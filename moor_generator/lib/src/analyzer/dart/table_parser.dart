//@dart=2.9
part of 'parser.dart';

/// Parses a [MoorTable] from a Dart class.
class TableParser {
  final MoorDartParser base;

  TableParser(this.base);

  Future<MoorTable> parseTable(ClassElement element) async {
    final sqlName = await _parseTableName(element);
    if (sqlName == null) return null;

    final columns = (await _parseColumns(element)).toList();
    final primaryKey = await _readPrimaryKey(element, columns);

    final dataClassInfo = _readDataClassInformation(columns, element);

    final table = MoorTable(
      fromClass: element,
      columns: columns,
      sqlName: escapeIfNeeded(sqlName),
      dartTypeName: dataClassInfo.enforcedName,
      existingRowClass: dataClassInfo.existingClass,
      generateReverseMapping: dataClassInfo.generateReverseMapping,
      primaryKey: primaryKey,
      overrideWithoutRowId: await _overrideWithoutRowId(element),
      declaration: DartTableDeclaration(element, base.step.file),
    );

    if (primaryKey != null && columns.any((element) => element.hasAI)) {
      base.step.errors.report(ErrorInDartCode(
        message: "Tables can't override primaryKey and use autoIncrement()",
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
      List<MoorColumn> columns, ClassElement element) {
    DartObject dataClassName;
    DartObject useRowClass;

    for (final annotation in element.metadata) {
      final computed = annotation.computeConstantValue();
      final annotationClass = computed.type.element.name;

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
    ClassElement existingClass;
    String constructorInExistingClass;
    bool generateReverseMapping;

    if (dataClassName != null) {
      name = dataClassName.getField('name').toStringValue();
    } else {
      name = dataClassNameForClassName(element.name);
    }

    if (useRowClass != null) {
      final type = useRowClass.getField('type').toTypeValue();
      constructorInExistingClass =
          useRowClass.getField('constructor').toStringValue();
      generateReverseMapping =
          useRowClass.getField('generateReverseMapping').toBoolValue();

      if (type is InterfaceType) {
        existingClass = type.element;
        name = existingClass.name;
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
            constructorInExistingClass, base.step.errors);
    return _DataClassInformation(name, verified, generateReverseMapping);
  }

  Future<String> _parseTableName(ClassElement element) async {
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

    final tableName = base.readStringLiteral(returnExpr, () {
      base.step.reportError(ErrorInDartCode(
          severity: Severity.criticalError,
          message:
              'This getter must return a string literal, and do nothing more',
          affectedElement: tableNameGetter));
    });

    return tableName;
  }

  Future<Set<MoorColumn>> _readPrimaryKey(
      ClassElement element, List<MoorColumn> columns) async {
    final primaryKeyGetter =
        element.lookUpGetter('primaryKey', element.library);

    if (primaryKeyGetter.isFromDefaultTable) {
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
    final expression = (body as ExpressionFunctionBody).expression;
    final parsedPrimaryKey = <MoorColumn>{};

    if (expression is SetOrMapLiteral) {
      for (final entry in expression.elements) {
        if (entry is Identifier) {
          final column = columns
              .singleWhere((column) => column.dartGetterName == entry.name);
          parsedPrimaryKey.add(column);
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

  Future<bool /*?*/ > _overrideWithoutRowId(ClassElement element) async {
    final getter = element.lookUpGetter('withoutRowId', element.library);

    // Was the getter overridden at all?
    if (getter.isFromDefaultTable) return null;

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

  Future<Iterable<MoorColumn>> _parseColumns(ClassElement element) async {
    final columnNames = element.allSupertypes
        .map((t) => t.element)
        .followedBy([element])
        .expand((e) => e.fields)
        .where((field) =>
            isColumn(field.type) &&
            field.getter != null &&
            !field.getter.isSynthetic)
        .map((field) => field.name)
        .toSet();

    final fields = columnNames.map((name) {
      final getter = element.getGetter(name) ??
          element.lookUpInheritedConcreteGetter(name, element.library);
      return getter.variable;
    });

    final results = await Future.wait(fields.map((field) async {
      final node =
          await base.loadElementDeclaration(field.getter) as MethodDeclaration;

      return await base.parseColumn(node, field.getter);
    }));

    return results.where((c) => c != null);
  }
}

class _DataClassInformation {
  final String /*?*/ enforcedName;
  final ExistingRowClass /*?*/ existingClass;
  final bool /*?*/ generateReverseMapping;

  _DataClassInformation(
      this.enforcedName, this.existingClass, this.generateReverseMapping);
}

extension on Element {
  bool get isFromDefaultTable {
    final parent = enclosingElement;

    return parent is ClassElement &&
        parent.name == 'Table' &&
        isFromMoor(parent.thisType);
  }
}
