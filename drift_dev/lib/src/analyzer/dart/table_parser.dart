part of 'parser.dart';

/// Parses a [DriftTable] from a Dart class.
class TableParser {
  final DriftDartParser base;

  TableParser(this.base);

  Future<DriftTable?> parseTable(ClassElement element) async {
    final sqlName = await _parseTableName(element);
    if (sqlName == null) return null;

    final columns = (await _parseColumns(element)).toList();
    final primaryKey = await _readPrimaryKey(element, columns);
    final uniqueKeys = await _readUniqueKeys(element, columns);

    final dataClassInfo = _readDataClassInformation(columns, element);

    final table = DriftTable(
      fromClass: element,
      columns: columns,
      sqlName: sqlName,
      dartTypeName: dataClassInfo.enforcedName,
      existingRowClass: dataClassInfo.existingClass,
      customParentClass: dataClassInfo.extending,
      primaryKey: primaryKey,
      uniqueKeys: uniqueKeys,
      overrideWithoutRowId: await _overrideWithoutRowId(element),
      declaration: DartTableDeclaration(element, base.step.file),
    );

    if (primaryKey != null && columns.any((element) => element.hasAI)) {
      base.step.errors.report(ErrorInDartCode(
        message: "Tables can't override primaryKey and use autoIncrement()",
        affectedElement: element,
      ));
    }

    if (primaryKey != null &&
        primaryKey.length == 1 &&
        primaryKey.first.features.contains(const UniqueKey())) {
      base.step.errors.report(ErrorInDartCode(
        message: 'Primary key column cannot have UNIQUE constraint',
        affectedElement: element,
      ));
    }

    if (uniqueKeys != null &&
        uniqueKeys.any((key) =>
            uniqueKeys.length == 1 &&
            key.first.features.contains(const UniqueKey()))) {
      base.step.errors.report(ErrorInDartCode(
        message:
            'Column provided in a single-column uniqueKey set already has a '
            'column-level UNIQUE constraint',
        affectedElement: element,
      ));
    }

    if (uniqueKeys != null &&
        primaryKey != null &&
        uniqueKeys
            .any((unique) => const SetEquality().equals(unique, primaryKey))) {
      base.step.errors.report(ErrorInDartCode(
        message: 'The uniqueKeys override contains the primary key, which is '
            'already unique by default.',
        affectedElement: element,
      ));
    }

    var index = 0;
    for (final converter in table.converters) {
      converter
        ..index = index++
        ..table = table;
    }

    return table;
  }

  _DataClassInformation _readDataClassInformation(
      List<DriftColumn> columns, ClassElement element) {
    DartObject? dataClassName;
    DartObject? useRowClass;

    for (final annotation in element.metadata) {
      final computed = annotation.computeConstantValue();
      final annotationClass = computed!.type!.element!.name;

      if (annotationClass == 'DataClassName') {
        dataClassName = computed;
      } else if (annotationClass == 'UseRowClass') {
        useRowClass = computed;
      }
    }

    if (dataClassName != null && useRowClass != null) {
      base.step.reportError(ErrorInDartCode(
        message: "A table can't be annotated with both @DataClassName and "
            '@UseRowClass',
        affectedElement: element,
      ));
    }

    String name;
    String? customParentClass;
    FoundDartClass? existingClass;
    String? constructorInExistingClass;
    bool? generateInsertable;

    if (dataClassName != null) {
      name = dataClassName.getField('name')!.toStringValue()!;
      customParentClass =
          parseCustomParentClass(name, dataClassName, element, base);
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
        existingClass = FoundDartClass(type.element, type.typeArguments);
        name = type.element.name;
      } else {
        base.step.reportError(ErrorInDartCode(
          message: 'The @UseRowClass annotation must be used with a class',
          affectedElement: element,
        ));
      }
    }

    final verified = existingClass == null
        ? null
        : validateExistingClass(columns, existingClass,
            constructorInExistingClass!, generateInsertable!, base.step);
    return _DataClassInformation(name, customParentClass, verified);
  }

  Future<String?> _parseTableName(ClassElement element) async {
    // todo allow override via a field (final String tableName = '') as well

    final tableNameGetter = element.lookUpGetter('tableName', element.library);
    if (tableNameGetter == null ||
        tableNameGetter.isFromDefaultTable ||
        tableNameGetter.isAbstract) {
      // class does not override tableName. So just use the dart class name
      // instead. Will use placed_orders for a class called PlacedOrders
      return ReCase(element.name).snakeCase;
    }

    // we expect something like get tableName => "myTableName", the getter
    // must do nothing more complicated
    final node = await base.loadElementDeclaration(tableNameGetter);
    final returnExpr = base.returnExpressionOfMethod(node as MethodDeclaration);
    if (returnExpr == null) return null;

    final tableName = base.readStringLiteral(returnExpr, () {
      base.step.reportError(ErrorInDartCode(
          severity: Severity.criticalError,
          message:
              'This getter must return a string literal, and do nothing more',
          affectedElement: tableNameGetter));
    });

    return tableName;
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

    final ast = await base.loadElementDeclaration(primaryKeyGetter)
        as MethodDeclaration;
    final body = ast.body;
    if (body is! ExpressionFunctionBody) {
      base.step.reportError(ErrorInDartCode(
          affectedElement: primaryKeyGetter,
          message: 'This must return a set literal using the => syntax!'));
      return null;
    }
    final expression = body.expression;
    final parsedPrimaryKey = <DriftColumn>{};

    if (expression is SetOrMapLiteral) {
      for (final entry in expression.elements) {
        if (entry is Identifier) {
          final column = columns.singleWhereOrNull(
              (column) => column.dartGetterName == entry.name);
          if (column == null) {
            base.step.reportError(
              ErrorInDartCode(
                affectedElement: primaryKeyGetter,
                affectedNode: entry,
                message: 'Column not found in this table',
              ),
            );
          } else {
            parsedPrimaryKey.add(column);
          }
        } else {
          print('Unexpected entry in expression.elements: $entry');
        }
      }
    } else {
      base.step.reportError(ErrorInDartCode(
          affectedElement: primaryKeyGetter,
          message: 'This must return a set literal!'));
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

    final ast =
        await base.loadElementDeclaration(uniqueKeyGetter) as MethodDeclaration;
    final body = ast.body;
    if (body is! ExpressionFunctionBody) {
      base.step.reportError(ErrorInDartCode(
          affectedElement: uniqueKeyGetter,
          message: 'This must return a list of set literal using the => '
              'syntax!'));
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
                  (column) => column.dartGetterName == entry.name);
              if (column == null) {
                base.step.reportError(
                  ErrorInDartCode(
                    affectedElement: uniqueKeyGetter,
                    affectedNode: entry,
                    message: 'Column not found in this table',
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
          base.step.reportError(ErrorInDartCode(
              affectedElement: uniqueKeyGetter,
              message: 'This must return a set list literal!'));
        }
      }
    } else {
      base.step.reportError(ErrorInDartCode(
          affectedElement: uniqueKeyGetter,
          message: 'This must return a set list literal!'));
    }

    return parsedUniqueKeys;
  }

  Future<bool?> _overrideWithoutRowId(ClassElement element) async {
    final getter = element.lookUpGetter('withoutRowId', element.library);

    // Was the getter overridden at all?
    if (getter == null || getter.isFromDefaultTable) return null;

    final ast = await base.loadElementDeclaration(getter) as MethodDeclaration;
    final expr = base.returnExpressionOfMethod(ast);

    if (expr == null) return null;

    if (expr is BooleanLiteral) {
      return expr.value;
    } else {
      base.step.reportError(ErrorInDartCode(
        affectedElement: getter,
        message: 'This must directly return a boolean literal.',
      ));
    }

    return null;
  }

  Future<Iterable<DriftColumn>> _parseColumns(ClassElement element) async {
    final columnNames = element.allSupertypes
        .map((t) => t.element)
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
      final node =
          await base.loadElementDeclaration(field.getter!) as MethodDeclaration;

      return await base.parseColumn(node, field.getter!);
    }));

    return results.whereType();
  }
}

class _DataClassInformation {
  final String enforcedName;
  final String? extending;
  final ExistingRowClass? existingClass;

  _DataClassInformation(
    this.enforcedName,
    this.extending,
    this.existingClass,
  );
}

extension on Element {
  bool get isFromDefaultTable {
    final parent = enclosingElement;

    return parent is ClassElement &&
        parent.name == 'Table' &&
        isFromMoor(parent.thisType);
  }
}
