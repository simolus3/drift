import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';

import '../../driver/error.dart';
import '../../results/results.dart';
import '../intermediate_state.dart';
import '../resolver.dart';
import '../shared/dart_types.dart';
import '../shared/data_class.dart';
import 'column.dart';
import 'helper.dart';

class DartTableResolver extends LocalElementResolver<DiscoveredDartTable> {
  DartTableResolver(super.file, super.discovered, super.resolver, super.state);

  @override
  Future<DriftElement> resolve() async {
    final element = discovered.dartElement;

    final pendingColumns = (await _parseColumns(element)).toList();
    final columns = [for (final column in pendingColumns) column.column];
    final primaryKey = await _readPrimaryKey(element, columns);
    final uniqueKeys = await _readUniqueKeys(element, columns);

    final dataClassInfo = _readDataClassInformation(columns, element);

    final references = <DriftElement>{};

    // Resolve local foreign key references in pending columns
    for (final column in pendingColumns) {
      if (column.referencesColumnInSameTable != null) {
        final ref =
            column.column.constraints.whereType<ForeignKeyReference>().first;
        final referencedColumn = columns.firstWhere(
            (e) => e.nameInDart == column.referencesColumnInSameTable);

        ref.otherColumn = referencedColumn;
      } else {
        for (final constraint in column.column.constraints) {
          if (constraint is ForeignKeyReference) {
            references.add(constraint.otherColumn.owner);
          }
        }
      }
    }

    final table = DriftTable(
      discovered.ownId,
      DriftDeclaration.dartElement(element),
      columns: columns,
      references: references.toList(),
      nameOfRowClass: dataClassInfo.enforcedName,
      existingRowClass: dataClassInfo.existingClass,
      customParentClass: dataClassInfo.extending,
      baseDartName: element.name,
      primaryKeyFromTableConstraint: primaryKey,
      tableConstraints: [
        for (final uniqueKey in uniqueKeys ?? const <Set<DriftColumn>>[])
          UniqueColumns(uniqueKey),
      ],
      withoutRowId: await _overrideWithoutRowId(element) ?? false,
    );

    if (primaryKey != null &&
        columns.any((c) => c.constraints.any((e) => e is PrimaryKeyColumn))) {
      reportError(DriftAnalysisError.forDartElement(
        element,
        "Tables can't override primaryKey and use autoIncrement()",
      ));
    }

    if (primaryKey != null &&
        primaryKey.length == 1 &&
        primaryKey.first.constraints.contains(const UniqueColumn())) {
      reportError(DriftAnalysisError.forDartElement(
        element,
        'Primary key column cannot have UNIQUE constraint',
      ));
    }

    if (uniqueKeys != null &&
        uniqueKeys.any((key) =>
            uniqueKeys.length == 1 &&
            key.first.constraints.contains(const UniqueColumn()))) {
      reportError(DriftAnalysisError.forDartElement(
        element,
        'Column provided in a single-column uniqueKey set already has a '
        'column-level UNIQUE constraint',
      ));
    }

    if (uniqueKeys != null &&
        primaryKey != null &&
        uniqueKeys
            .any((unique) => const SetEquality().equals(unique, primaryKey))) {
      reportError(DriftAnalysisError.forDartElement(
        element,
        'The uniqueKeys override contains the primary key, which is '
        'already unique by default.',
      ));
    }

    return table;
  }

  _DataClassInformation _readDataClassInformation(
      List<DriftColumn> columns, ClassElement element) {
    DartObject? dataClassName;
    DartObject? useRowClass;

    for (final annotation in element.metadata) {
      final computed = annotation.computeConstantValue();
      final annotationClass = computed!.type!.nameIfInterfaceType;

      if (annotationClass == 'DataClassName') {
        dataClassName = computed;
      } else if (annotationClass == 'UseRowClass') {
        useRowClass = computed;
      }
    }

    if (dataClassName != null && useRowClass != null) {
      reportError(DriftAnalysisError.forDartElement(
        element,
        "A table can't be annotated with both @DataClassName and @UseRowClass",
      ));
    }

    String name;
    AnnotatedDartCode? customParentClass;
    FoundDartClass? existingClass;
    String? constructorInExistingClass;
    bool? generateInsertable;

    if (dataClassName != null) {
      name = dataClassName.getField('name')!.toStringValue()!;
      customParentClass =
          parseCustomParentClass(name, dataClassName, element, this);
    } else {
      name = dataClassNameForClassName(element.name);
    }

    if (useRowClass != null) {
      final type = useRowClass.getField('type')!.toTypeValue();
      constructorInExistingClass =
          useRowClass.getField('constructor')!.toStringValue()!;
      generateInsertable =
          useRowClass.getField('generateInsertable')!.toBoolValue()!;

      if (type is InterfaceType) {
        existingClass = FoundDartClass(type.element2, type.typeArguments);
        name = type.element2.name;
      } else {
        reportError(DriftAnalysisError.forDartElement(
          element,
          'The @UseRowClass annotation must be used with a class',
        ));
      }
    }

    final verified = existingClass == null
        ? null
        : validateExistingClass(columns, existingClass,
            constructorInExistingClass!, generateInsertable!, this);
    return _DataClassInformation(name, customParentClass, verified);
  }

  Future<Set<DriftColumn>?> _readPrimaryKey(
      ClassElement element, List<DriftColumn> columns) async {
    final primaryKeyGetter =
        element.lookUpGetter('primaryKey', element.library);

    if (primaryKeyGetter == null || primaryKeyGetter.isFromDefaultTable) {
      // resolved primaryKey is from the Table dsl superclass. That means there
      // is no primary key
      return null;
    }

    final ast = await resolver.driver.backend
        .loadElementDeclaration(primaryKeyGetter) as MethodDeclaration;
    final body = ast.body;
    if (body is! ExpressionFunctionBody) {
      reportError(DriftAnalysisError.forDartElement(primaryKeyGetter,
          'This must return a set literal using the => syntax!'));
      return null;
    }
    final expression = body.expression;
    final parsedPrimaryKey = <DriftColumn>{};

    if (expression is SetOrMapLiteral) {
      for (final entry in expression.elements) {
        if (entry is Identifier) {
          final column = columns
              .singleWhereOrNull((column) => column.nameInDart == entry.name);
          if (column == null) {
            reportError(
              DriftAnalysisError.inDartAst(
                  primaryKeyGetter, entry, 'Column not found in this table'),
            );
          } else {
            parsedPrimaryKey.add(column);
          }
        } else {
          print('Unexpected entry in expression.elements: $entry');
        }
      }
    } else {
      reportError(DriftAnalysisError.forDartElement(
          primaryKeyGetter, 'This must return a set literal!'));
    }

    return parsedPrimaryKey;
  }

  Future<List<Set<DriftColumn>>?> _readUniqueKeys(
      ClassElement element, List<DriftColumn> columns) async {
    final uniqueKeyGetter = element.lookUpGetter('uniqueKeys', element.library);

    if (uniqueKeyGetter == null || uniqueKeyGetter.isFromDefaultTable) {
      // resolved uniqueKeys is from the Table dsl superclass. That means there
      // is no unique key list
      return null;
    }

    final ast = await resolver.driver.backend
        .loadElementDeclaration(uniqueKeyGetter) as MethodDeclaration;
    final body = ast.body;
    if (body is! ExpressionFunctionBody) {
      reportError(DriftAnalysisError.forDartElement(uniqueKeyGetter,
          'This must return a list of set literal using the => syntax!'));
      return null;
    }
    final expression = body.expression;
    final parsedUniqueKeys = <Set<DriftColumn>>[];

    if (expression is ListLiteral) {
      for (final keySet in expression.elements) {
        if (keySet is SetOrMapLiteral) {
          final uniqueKey = <DriftColumn>{};
          for (final entry in keySet.elements) {
            if (entry is Identifier) {
              final column = columns.singleWhereOrNull(
                  (column) => column.nameInDart == entry.name);
              if (column == null) {
                reportError(
                  DriftAnalysisError.inDartAst(
                    uniqueKeyGetter,
                    entry,
                    'Column not found in this table',
                  ),
                );
              } else {
                uniqueKey.add(column);
              }
            } else {
              print('Unexpected entry in expression.elements: $entry');
            }
          }
          parsedUniqueKeys.add(uniqueKey);
        } else {
          reportError(DriftAnalysisError.forDartElement(
              uniqueKeyGetter, 'This must return a set list literal!'));
        }
      }
    } else {
      reportError(DriftAnalysisError.forDartElement(
          uniqueKeyGetter, 'This must return a set list literal!'));
    }

    return parsedUniqueKeys;
  }

  Future<bool?> _overrideWithoutRowId(ClassElement element) async {
    final getter = element.lookUpGetter('withoutRowId', element.library);

    // Was the getter overridden at all?
    if (getter == null || getter.isFromDefaultTable) return null;

    final ast = await resolver.driver.backend.loadElementDeclaration(getter)
        as MethodDeclaration;
    final expr = returnExpressionOfMethod(ast);

    if (expr == null) return null;

    if (expr is BooleanLiteral) {
      return expr.value;
    } else {
      reportError(DriftAnalysisError.forDartElement(
        getter,
        'This must directly return a boolean literal.',
      ));
    }

    return null;
  }

  Future<Iterable<PendingColumnInformation>> _parseColumns(
      ClassElement element) async {
    final columnNames = element.allSupertypes
        .map((t) => t.element2)
        .followedBy([element])
        .expand((e) => e.fields)
        .where((field) =>
            isColumn(field.type) &&
            field.getter != null &&
            !field.getter!.isSynthetic)
        .map((field) => field.name)
        .toSet();

    final fields = columnNames.map((name) {
      final getter = element.getGetter(name) ??
          element.lookUpInheritedConcreteGetter(name, element.library);
      return getter!.variable;
    });

    final results = await Future.wait(fields.map((field) async {
      final node = await resolver.driver.backend
          .loadElementDeclaration(field.getter!) as MethodDeclaration;

      return await _parseColumn(node, field.getter!);
    }));

    return results.whereType();
  }

  Future<PendingColumnInformation?> _parseColumn(
      MethodDeclaration declaration, Element element) async {
    return ColumnParser(this).parse(declaration, element);
  }
}

class _DataClassInformation {
  final String enforcedName;
  final AnnotatedDartCode? extending;
  final ExistingRowClass? existingClass;

  _DataClassInformation(
    this.enforcedName,
    this.extending,
    this.existingClass,
  );
}
