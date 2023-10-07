import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show DriftSqlType;
import 'package:drift_dev/src/analysis/driver/error.dart';
import 'package:recase/recase.dart';

import '../../results/results.dart';
import '../intermediate_state.dart';
import '../resolver.dart';
import 'helper.dart';

class DartViewResolver extends LocalElementResolver<DiscoveredDartView> {
  DartViewResolver(super.file, super.discovered, super.resolver, super.state);

  @override
  Future<DriftElement> resolve() async {
    final staticReferences = await _parseStaticReferences();
    final structure = await _parseSelectStructure(staticReferences);
    final columns = await _parseColumns(structure, staticReferences);
    final dataClassInfo = await DataClassInformation.resolve(
        this, columns, discovered.dartElement);

    return DriftView(
      discovered.ownId,
      DriftDeclaration.dartElement(discovered.dartElement),
      columns: columns,
      nameOfRowClass: dataClassInfo.enforcedName,
      existingRowClass: dataClassInfo.existingClass,
      customParentClass: dataClassInfo.extending,
      entityInfoName: '\$${discovered.dartElement.name}View',
      source: DartViewSource(
        structure.dartQuerySource,
        structure.primarySource,
        staticReferences,
      ),
      references: [
        for (final reference in staticReferences) reference.table,
      ],
    );
  }

  Future<List<TableReferenceInDartView>> _parseStaticReferences() async {
    return await Stream.fromIterable(discovered.dartElement.allSupertypes
            .map((t) => t.element)
            .followedBy([discovered.dartElement]).expand((e) => e.fields))
        .asyncMap((field) => _getStaticReference(field))
        .where((ref) => ref != null)
        .cast<TableReferenceInDartView>()
        .toList();
  }

  Future<TableReferenceInDartView?> _getStaticReference(
      FieldElement field) async {
    final type = field.type;
    final knownTypes = await resolver.driver.loadKnownTypes();
    final typeSystem = field.library.typeSystem;

    if (type is! InterfaceType ||
        !typeSystem.isAssignableTo(type, knownTypes.tableType)) return null;

    if (field.getter != null) {
      try {
        final node =
            await resolver.driver.backend.loadElementDeclaration(field.getter!);
        if (node is MethodDeclaration && node.body is EmptyFunctionBody) {
          final table = await resolveDartReferenceOrReportError<DriftTable>(
              type.element, (msg) {
            return DriftAnalysisError.inDartAst(
                field, node.returnType ?? node.name, msg);
          });

          if (table != null) {
            final name = node.name.lexeme;
            return TableReferenceInDartView(table, name);
          }
        }
      } catch (_) {}
    }
    return null;
  }

  Future<_ParsedDartViewSelect> _parseSelectStructure(
    List<TableReferenceInDartView> references,
  ) async {
    MethodElement? as;

    _ParsedDartViewSelect error(String message) {
      reportError(DriftAnalysisError.forDartElement(
          as ?? discovered.dartElement, message));

      return _ParsedDartViewSelect(
        null,
        const [],
        const [],
        const [],
        AnnotatedDartCode.build(
          (builder) => builder.addText(
            "(throw 'Invalid view (analysis error). Please see the log of "
            "running `build_runner build`')",
          ),
        ),
      );
    }

    as = discovered.dartElement.methods
        .where((method) => method.name == 'as')
        .firstOrNull;

    if (as == null) {
      return error(
          'Missing an `as()` method declaring the query for this view');
    }

    final node = await resolver.driver.backend.loadElementDeclaration(as);
    final body = (node as MethodDeclaration).body;
    if (body is! ExpressionFunctionBody) {
      return error(
        'The `as()` query declaration must be an expression (=>). '
        'Block function body `{ return x; }` not acceptable.',
      );
    }

    final innerJoins = <TableReferenceInDartView>[];
    final outerJoins = <TableReferenceInDartView>[];

    // We have something like Query as() => select([...]).from(foo).join(...).
    // First, crawl up so get the `select`:
    Expression? target = body.expression;
    for (;;) {
      if (target is MethodInvocation) {
        if (target.target == null) break;

        final name = target.methodName.toSource();
        if (name == 'join') {
          final joinList = target.argumentList.arguments[0] as ListLiteral;
          for (final entry in joinList.elements) {
            // Do we have something like innerJoin(foo, bar)?
            if (entry is MethodInvocation) {
              final isInnerJoin = entry.methodName.toSource() == 'innerJoin';
              final table = references.firstWhereOrNull((element) =>
                  element.name == entry.argumentList.arguments[0].toSource());

              if (table != null) {
                final list = isInnerJoin ? innerJoins : outerJoins;
                list.add(table);
              }
            }
          }
        }

        target = target.target;
      } else if (target is CascadeExpression) {
        target = target.target;
      } else {
        return error(
            'The `as()` query declaration contains invalid expression type '
            '${target.runtimeType}');
      }
    }

    if (target.methodName.toString() != 'select') {
      return error('The `as()` query declaration must be started '
          'with `select(columns).from(table)');
    }

    final columnListLiteral = target.argumentList.arguments[0] as ListLiteral;
    final columnExpressions =
        columnListLiteral.elements.whereType<Expression>().toList();

    target = target.parent as MethodInvocation;
    if (target.methodName.toString() != 'from') {
      return error('The `as()` query declaration must be started '
          'with `select(columns).from(table)');
    }

    final from = target.argumentList.arguments[0].toSource();
    final resolvedFrom =
        references.firstWhereOrNull((element) => element.name == from);
    if (resolvedFrom == null) {
      reportError(
        DriftAnalysisError.inDartAst(
          as,
          target.argumentList,
          'Table reference `$from` not found, is it added to this '
          'view as a getter?',
        ),
      );
    }

    final query = AnnotatedDartCode.build(
        (builder) => builder.addAstNode(body.expression, exclude: {target!}));
    return _ParsedDartViewSelect(
        resolvedFrom, innerJoins, outerJoins, columnExpressions, query);
  }

  Future<List<DriftColumn>> _parseColumns(
    _ParsedDartViewSelect structure,
    List<TableReferenceInDartView> references,
  ) async {
    final columns = <DriftColumn>[];

    for (final columnReference in structure.selectedColumns) {
      final parts = columnReference.toSource().split('.');

      // Column reference like `foo.bar`, where `foo` is a table that has been
      // referenced in this view.
      if (parts.length > 1) {
        final reference =
            references.firstWhereOrNull((ref) => ref.name == parts[0]);
        if (reference == null) {
          reportError(DriftAnalysisError.inDartAst(
            discovered.dartElement,
            columnReference,
            'Table named `${parts[0]}` not found! Maybe not '
            'included in @DriftDatabase or not belongs to this database',
          ));
          continue;
        }

        final column = reference.table.columns
            .firstWhere((col) => col.nameInDart == parts[1]);

        columns.add(DriftColumn(
          declaration: DriftDeclaration.dartElement(discovered.dartElement),
          sqlType: column.sqlType,
          nullable: column.nullable || structure.referenceIsNullable(reference),
          nameInDart: column.nameInDart,
          nameInSql: column.nameInSql,
          constraints: [
            ColumnGeneratedAs(
                AnnotatedDartCode.build(
                    (b) => b.addText('${reference.name}.${column.nameInDart}')),
                false),
          ],
          typeConverter: column.typeConverter,
          foreignConverter: true,
        ));
      } else {
        // Locally-defined column, defined as a getter on this view class.
        final getter = discovered.dartElement.thisType.getGetter(parts[0]);

        if (getter == null) {
          reportError(DriftAnalysisError.inDartAst(
            discovered.dartElement,
            columnReference,
            'This column could not be found in the local view.',
          ));
          continue;
        }

        final dartType = (getter.returnType as InterfaceType).typeArguments[0];
        final typeName = dartType.nameIfInterfaceType!;
        final sqlType = _dartTypeToColumnType(typeName);

        if (sqlType == null) {
          final String errorMessage;
          if (typeName == 'dynamic') {
            errorMessage = 'You must specify Expression<> type argument';
          } else {
            errorMessage =
                'Invalid Expression<> type argument `$typeName` found. '
                'Must be one of: '
                'bool, String, int, DateTime, Uint8List, double';
          }

          reportError(DriftAnalysisError.forDartElement(getter, errorMessage));
          continue;
        }

        final node = await resolver.driver.backend
            .loadElementDeclaration(getter) as MethodDeclaration;
        final expression = (node.body as ExpressionFunctionBody).expression;

        columns.add(DriftColumn(
          declaration: DriftDeclaration.dartElement(getter),
          sqlType: ColumnType.drift(sqlType),
          nameInDart: getter.name,
          nameInSql: ReCase(getter.name).snakeCase,
          nullable: true,
          constraints: [
            ColumnGeneratedAs(AnnotatedDartCode.ast(expression), false)
          ],
        ));
      }
    }

    return columns;
  }

  DriftSqlType? _dartTypeToColumnType(String name) {
    return const {
      'bool': DriftSqlType.bool,
      'String': DriftSqlType.string,
      'int': DriftSqlType.int,
      'BigInt': DriftSqlType.bigInt,
      'DateTime': DriftSqlType.dateTime,
      'Uint8List': DriftSqlType.blob,
      'double': DriftSqlType.double,
    }[name];
  }
}

class _ParsedDartViewSelect {
  final TableReferenceInDartView? primarySource;
  final List<TableReferenceInDartView> innerJoins;
  final List<TableReferenceInDartView> outerJoins;

  final List<Expression> selectedColumns;
  final AnnotatedDartCode dartQuerySource;

  _ParsedDartViewSelect(this.primarySource, this.innerJoins, this.outerJoins,
      this.selectedColumns, this.dartQuerySource);

  bool referenceIsNullable(TableReferenceInDartView ref) {
    return ref != primarySource && !innerJoins.contains(ref);
  }
}
