part of 'parser.dart';

/// Parses a [MoorTable] from a Dart class.
class TableParser {
  final MoorDartParser base;

  TableParser(this.base);

  Future<MoorTable?> parseTable(ClassElement element) async {
    final dbTable = ORMTableParser.getDbTableAnnotation(element);

    String? sqlName;
    if (dbTable == null) {
      sqlName = await _parseTableName(element);
    } else {
      sqlName = dbTable.getField('name')?.toStringValue() ??
          ReCase(element.name).snakeCase;
    }

    if (sqlName == null) return null;

    var overrideTableConstraints = <String>[];
    List<MoorColumn> columns;
    Set<MoorColumn>? primaryKey;
    _DataClassInformation dataClassInfo;
    bool? overrideWithoutRowId;

    if (dbTable == null) {
      columns = (await _parseColumns(element)).toList();
      primaryKey = await _readPrimaryKey(element, columns);
      dataClassInfo = _readDataClassInformation(columns, element);
      overrideWithoutRowId = await _overrideWithoutRowId(element);
    } else {
      final dbColumns = ORMTableParser.getDbColumns(element);
      columns = (await ORMTableParser.parseDbColumns(dbColumns, base)).toList();
      primaryKey = await ORMTableParser.readDbPrimaryKey(columns);
      dataClassInfo = ORMTableParser.readDbDataClassInformation(
          columns, element, dbTable, base);
      overrideTableConstraints = dbTable
          .getField('customConstraints')
          ?.toListValue()
          ?.map((e) => e.toStringValue())
          .whereNotNull()
          .toList() ?? [];
      overrideWithoutRowId = dbTable.getField('withoutRowId')?.toBoolValue();
    }

    final table = MoorTable(
      fromClass: element,
      columns: columns,
      sqlName: escapeIfNeeded(sqlName),
      dartTypeName: dataClassInfo.enforcedName,
      existingRowClass: dataClassInfo.existingClass,
      primaryKey: primaryKey,
      overrideWithoutRowId: overrideWithoutRowId,
      declaration: DartTableDeclaration(element, base.step.file),
      isOrmTable: dbTable != null,
      overrideTableConstraints: overrideTableConstraints,
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
    ClassElement? existingClass;
    String? constructorInExistingClass;

    if (dataClassName != null) {
      name = dataClassName.getField('name')!.toStringValue()!;
    } else {
      name = dataClassNameForClassName(element.name);
    }

    if (useRowClass != null) {
      final type = useRowClass.getField('type')!.toTypeValue();
      constructorInExistingClass =
          useRowClass.getField('constructor')!.toStringValue()!;

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
            constructorInExistingClass!, base.step.errors);
    return _DataClassInformation(name, verified);
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

  Future<Set<MoorColumn>?> _readPrimaryKey(
      ClassElement element, List<MoorColumn> columns) async {
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

  Future<Iterable<MoorColumn>> _parseColumns(ClassElement element) async {
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
  final ExistingRowClass? existingClass;

  _DataClassInformation(this.enforcedName, this.existingClass);
}

extension on Element {
  bool get isFromDefaultTable {
    final parent = enclosingElement;

    return parent is ClassElement &&
        parent.name == 'Table' &&
        isFromMoor(parent.thisType);
  }
}

/// ORM
class DbColumnField {
  final FieldElement field;
  final DartObject annotation;
  final ElementAnnotation annotationElement;
  final bool isForeignKey;
  final bool isEnumField;

  const DbColumnField(
    this.field,
    this.annotation,
    this.annotationElement,
    this.isForeignKey,
    this.isEnumField,
  );
}

class ORMTableParser {
  static DartObject? getDbTableAnnotation(ClassElement element) {
    for (final annotation in element.metadata) {
      final computed = annotation.computeConstantValue();
      final annotationClass = computed?.type?.element?.name;

      if (annotationClass == 'OrmTable') {
        return computed;
      }
    }

    return null;
  }

  static DbColumnField? getDbColumnAnnotation(FieldElement element) {
    DartObject? dbAnnotation;
    ElementAnnotation? dbAnnotationElement;

    var isForeignKey = false;
    var isEnumColumn = false;
    for (final annotation in element.metadata) {
      final computed = annotation.computeConstantValue();
      final annotationClass = computed?.type?.element?.name;

      isForeignKey = annotationClass == 'ForeignKeyColumn';
      isEnumColumn = annotationClass == 'EnumColumn';
      if (annotationClass == 'ColumnDef' || isForeignKey || isEnumColumn) {
        dbAnnotation = computed;
        dbAnnotationElement = annotation;
      }
    }

    return dbAnnotation == null
        ? null
        : DbColumnField(
            element,
            dbAnnotation,
            dbAnnotationElement!,
            isForeignKey,
            isEnumColumn,
          );
  }

  static _DataClassInformation readDbDataClassInformation(
      List<MoorColumn> columns,
      ClassElement element,
      DartObject annotation,
      MoorDartParser base) {
    final constructorInExistingClass =
        annotation.getField('dbConstructor')?.toStringValue() ?? '';
    final existingClass = element.thisType.element;
    final name = existingClass.name;

    final verified = validateExistingClass(
        columns, existingClass, constructorInExistingClass, base.step.errors);
    return _DataClassInformation(name, verified);
  }

  static Future<Set<MoorColumn>?> readDbPrimaryKey(
      List<MoorColumn> columns) async {
    final primaryKeys = columns.where((element) => element.isPrimaryKey);
    return primaryKeys.isEmpty ? null : primaryKeys.toSet();
  }

  static Iterable<DbColumnField> getDbColumns(ClassElement element) {
    return element.fields
        .map(getDbColumnAnnotation)
        .where((field) => field != null)
        .whereNotNull()
        .toSet();
  }

  static Future<Iterable<MoorColumn>> parseDbColumns(
      Iterable<DbColumnField> fields, MoorDartParser base) async {
    final results = await Future.wait(fields.map((field) async {
      return await base.parseOrmColumn(field);
    }));

    return results.where((c) => c != null);
  }
}
