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
import '../shared/data_class.dart';
import 'helper.dart';

// TODO: We can know about columns before crawling dependencies, refactor this
// to a two-stage resolver.
final class DartViewResolver
    extends SingleStageElementResolver<DiscoveredDartView> {
  DartViewResolver(super.file, super.discovered, super.resolver, super.state);

  @override
  void addInCircularReferenceError(List<DriftElementId> ids) {
    final formatted = ids.map((e) => e.name).join(', ');

    reportError(
      DriftAnalysisError.forDartElement(
        discovered.dartElement,
        'This view is part of a circular reference and cannot be '
        'resolved. Reference cycle: $formatted',
      ),
    );
  }

  @override
  Future<Future<DriftElement> Function(SingleStageResolvedDependencies)>
  resolveDependencies() async {
    final staticReferences = await _parseStaticReferences();

    return (SingleStageResolvedDependencies deps) {
      return _resolveWithRefs(staticReferences, deps);
    };
  }

  Future<DriftElement> _resolveWithRefs(
    List<TableReference> refs,
    SingleStageResolvedDependencies resolved,
  ) async {
    final staticReferences = await _parseStaticReferences();
    final structure = await _parseSelectStructure(staticReferences);
    final columns = await _parseColumns(structure, staticReferences, resolved);
    final dataClassInfo = await DataClassInformation.resolve(
      this,
      columns,
      discovered.dartElement,
    );

    return DriftView(
      resolver.ownElementReference,
      DriftDeclaration.dartElement(discovered.dartElement),
      columns: columns,
      nameOfRowClass:
          dataClassInfo.enforcedName ??
          dataClassNameForClassName(discovered.dartElement.name!),
      existingRowClass: dataClassInfo.existingClass,
      customParentClass: dataClassInfo.extending,
      interfacesForRowClass: dataClassInfo.interfaces,
      entityInfoName: '\$${discovered.dartElement.name}View',
      source: DartViewSource(
        structure.dartQuerySource,
        structure.primarySource?.resolved,
        staticReferences.map((e) => e.resolved).toList(),
        structure.staticSource,
      ),
      references: [
        for (final reference in staticReferences) reference.resolved.table,
      ],
    );
  }

  Future<List<TableReference>> _parseStaticReferences() async {
    return await Stream.fromIterable(
          discovered.dartElement.allSupertypes
              .map((t) => t.element)
              .followedBy([discovered.dartElement])
              .expand((e) => e.fields),
        )
        .asyncMap((field) => _getStaticReference(field))
        .where((ref) => ref != null)
        .cast<TableReference>()
        .toList();
  }

  Future<TableReference?> _getStaticReference(FieldElement field) async {
    final type = field.type;
    final knownTypes = await resolver.driver.knownTypes;
    final typeSystem = field.library.typeSystem;

    if (type is! InterfaceType ||
        !typeSystem.isAssignableTo(type, knownTypes.tableType)) {
      return null;
    }

    if (field.getter case final getter?) {
      try {
        final node = await resolver.driver.backend.loadElementDeclaration(
          getter,
        );
        if (node is MethodDeclaration && node.body is EmptyFunctionBody) {
          final table = await resolveDartReferenceOrReportError(type.element, (
            msg,
          ) {
            return DriftAnalysisError.inDartAst(
              field,
              node.returnType ?? node.name,
              msg,
            );
          }, enforceKind: DriftElementKind.table);

          if (table != null) {
            final name = node.name.lexeme;
            return TableReference(
              TableReferenceInDartView(table.reference, name),
              table,
            );
          }
        }
      } catch (_) {}
    }
    return null;
  }

  Future<_ParsedDartViewSelect> _parseSelectStructure(
    List<TableReference> references,
  ) async {
    MethodElement? as;

    _ParsedDartViewSelect error(String message) {
      reportError(
        DriftAnalysisError.forDartElement(
          as ?? discovered.dartElement,
          message,
        ),
      );

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
        'Missing an `as()` method declaring the query for this view',
      );
    }

    final node = await resolver.driver.backend.loadElementDeclaration(as);
    final body = (node as MethodDeclaration).body;
    if (body is! ExpressionFunctionBody) {
      return error(
        'The `as()` query declaration must be an expression (=>). '
        'Block function body `{ return x; }` not acceptable.',
      );
    }

    final innerJoins = <TableReference>[];
    final outerJoins = <TableReference>[];

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
              final table = references.firstWhereOrNull(
                (element) =>
                    element.resolved.name ==
                    entry.argumentList.arguments[0].toSource(),
              );

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
          '${target.runtimeType}',
        );
      }
    }

    if (target.methodName.toString() != 'select') {
      return error(
        'The `as()` query declaration must be started '
        'with `select(columns).from(table)',
      );
    }

    final columnListLiteral = target.argumentList.arguments[0] as ListLiteral;
    final columnExpressions = columnListLiteral.elements
        .whereType<Expression>()
        .toList();

    target = target.parent as MethodInvocation;
    if (target.methodName.toString() != 'from') {
      return error(
        'The `as()` query declaration must be started '
        'with `select(columns).from(table)',
      );
    }

    final from = target.argumentList.arguments[0].toSource();
    final resolvedFrom = references.firstWhereOrNull(
      (element) => element.resolved.name == from,
    );
    if (resolvedFrom == null &&
        !resolver.driver.options.assumeCorrectReference) {
      reportError(
        DriftAnalysisError.inDartAst(
          as,
          target.argumentList,
          'Table reference `$from` not found, is it added to this '
          'view as a getter?',
        ),
      );
    }
    AnnotatedDartCode query;
    if (resolvedFrom == null &&
        resolver.driver.options.assumeCorrectReference) {
      query = AnnotatedDartCode.build(
        (builder) => builder.addText(
          body.expression.toSource().replaceAll(target!.toSource(), ''),
        ),
      );
    } else {
      query = AnnotatedDartCode.build(
        (builder) => builder.addAstNode(body.expression, exclude: {target!}),
      );
    }

    return _ParsedDartViewSelect(
      resolvedFrom,
      innerJoins,
      outerJoins,
      columnExpressions,
      query,
      from,
    );
  }

  DriftColumn? _readTableColumnReference(
    PrefixedIdentifier expression,
    _ParsedDartViewSelect structure,
    List<TableReference> references,
    SingleStageResolvedDependencies dependencies, {
    bool warnOnUnresolved = true,
    ({String dart, String sql})? name,
  }) {
    final referencedTableGetter = expression.prefix.name;
    final referencedColumnName = expression.identifier.name;

    final reference = references.firstWhereOrNull(
      (ref) => ref.resolved.name == referencedTableGetter,
    );
    final resolvedTable =
        dependencies.resolveNullable(reference?.dependency) as DriftTable?;

    if (reference == null || resolvedTable == null) {
      if (warnOnUnresolved) {
        reportError(
          DriftAnalysisError.inDartAst(
            discovered.dartElement,
            expression,
            'Table named `$referencedTableGetter` not found! Maybe not '
            'included in @DriftDatabase or not belongs to this database',
          ),
        );
      }

      return null;
    }

    final column = resolvedTable.columns.firstWhere(
      (col) => col.nameInDart == referencedColumnName,
    );
    final (:dart, :sql) = name ?? structure.uniqueColumnName(column);

    return DriftColumn(
      declaration: DriftDeclaration.dartElement(discovered.dartElement),
      sqlType: column.sqlType,
      nullable: column.nullable || structure.referenceIsNullable(reference),
      nameInDart: dart,
      nameInSql: sql,
      constraints: [
        ColumnGeneratedAs(
          AnnotatedDartCode.build(
            (b) => b.addText('${reference.resolved.name}.${column.nameInDart}'),
          ),
          false,
        ),
      ],
      typeConverter: column.typeConverter,
      foreignConverter: true,
    );
  }

  Future<List<DriftColumn>> _parseColumns(
    _ParsedDartViewSelect structure,
    List<TableReference> references,
    SingleStageResolvedDependencies dependencies,
  ) async {
    final columns = <DriftColumn>[];

    for (final columnReference in structure.selectedColumns) {
      if (columnReference case PrefixedIdentifier tableColumnReference) {
        // Column reference like `foo.bar`, where `foo` is a table that has been
        // referenced in this view.
        final parsed = _readTableColumnReference(
          tableColumnReference,
          structure,
          references,
          dependencies,
        );
        if (parsed != null) {
          columns.add(parsed);
        }
      } else if (columnReference case SimpleIdentifier localColumn) {
        // Locally-defined column, defined as a getter on this view class.
        final getter = discovered.dartElement.thisType.getGetter(
          localColumn.name,
        );

        if (getter == null) {
          reportError(
            DriftAnalysisError.inDartAst(
              discovered.dartElement,
              columnReference,
              'This column could not be found in the local view.',
            ),
          );
          continue;
        }

        final node =
            await resolver.driver.backend.loadElementDeclaration(getter)
                as MethodDeclaration;
        final nameInDart = getter.name!;
        final nameInSql = ReCase(nameInDart).snakeCase;

        final expression = (node.body as ExpressionFunctionBody).expression;
        if (expression is PrefixedIdentifier) {
          // Column defined as Expression<int> get id => joinedTable.id;
          // This might be a reference to a joined table, in which case we want
          // to special-case it to ensure we keep nullability and type
          // converters.
          final parsed = _readTableColumnReference(
            expression,
            structure,
            references,
            dependencies,
            warnOnUnresolved: false,
            name: (dart: nameInDart, sql: nameInSql),
          );
          if (parsed != null) {
            columns.add(parsed);
            continue;
          }
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

        columns.add(
          DriftColumn(
            declaration: DriftDeclaration.dartElement(getter),
            sqlType: ColumnType.drift(sqlType),
            nameInDart: nameInDart,
            nameInSql: nameInSql,
            nullable: true,
            constraints: [
              resolver.driver.options.assumeCorrectReference
                  ? ColumnGeneratedAs(
                      AnnotatedDartCode.build((builder) {
                        builder.addText(expression.toSource());
                      }),
                      false,
                    )
                  : ColumnGeneratedAs(AnnotatedDartCode.ast(expression), false),
            ],
          ),
        );
      } else {
        reportError(
          DriftAnalysisError.inDartAst(
            discovered.dartElement,
            columnReference,
            'Entries in select must reference columns as getters on the view, or '
            'columns referenced from a joined table.',
          ),
        );
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
  final TableReference? primarySource;
  final List<TableReference> innerJoins;
  final List<TableReference> outerJoins;

  final List<Expression> selectedColumns;
  final AnnotatedDartCode dartQuerySource;
  final Set<String> columnNames = {};

  final String? staticSource;
  _ParsedDartViewSelect(
    this.primarySource,
    this.innerJoins,
    this.outerJoins,
    this.selectedColumns,
    this.dartQuerySource, [
    this.staticSource,
  ]);

  bool referenceIsNullable(TableReference ref) {
    return ref != primarySource && !innerJoins.contains(ref);
  }

  ({String dart, String sql}) uniqueColumnName(DriftColumn source) {
    final name = source.nameInDart;
    if (columnNames.add(name)) {
      // No conflicting column exists.
      return (dart: name, sql: source.nameInSql);
    }

    var suffix = 1;
    while (!columnNames.add('$name$suffix')) {
      suffix++;
    }

    return (dart: '$name$suffix', sql: '${source.nameInSql}$suffix');
  }
}

final class TableReference {
  final TableReferenceInDartView resolved;
  final DependencyToken dependency;

  TableReference(this.resolved, this.dependency);
}
