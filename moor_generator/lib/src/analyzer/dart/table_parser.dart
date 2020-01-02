part of 'parser.dart';

/// Parses a [MoorTable] from a Dart class.
class TableParser {
  final MoorDartParser base;

  TableParser(this.base);

  Future<MoorTable> parseTable(ClassElement element) async {
    final sqlName = await _parseTableName(element);
    if (sqlName == null) return null;

    final columns = await _parseColumns(element);

	final variables = await _parseVariables(element);

    final table = MoorTable(
      fromClass: element,
      columns: columns,
	  variables: variables,
      sqlName: escapeIfNeeded(sqlName),
      dartTypeName: _readDartTypeName(element),
      primaryKey: await _readPrimaryKey(element, columns),
      declaration: DartTableDeclaration(element, base.step.file),
    );

    var index = 0;
    for (final converter in table.converters) {
      converter
        ..index = index++
        ..table = table;
    }

    return table;
  }

  String _readDartTypeName(ClassElement element) {
    final nameAnnotation = element.metadata.singleWhere(
        (e) => e.computeConstantValue().type.name == 'DataClassName',
        orElse: () => null);

    if (nameAnnotation == null) {
      return dataClassNameForClassName(element.name);
    } else {
      return nameAnnotation.constantValue.getField('name').toStringValue();
    }
  }

  Future<String> _parseTableName(ClassElement element) async {
    // todo allow override via a field (final String tableName = '') as well

    final tableNameGetter = element.getGetter('tableName');
    if (tableNameGetter == null) {
      // class does not override tableName. So just use the dart class name
      // instead. Will use placed_orders for a class called PlacedOrders
      return ReCase(element.name).snakeCase;
    }

    // we expect something like get tableName => "myTableName", the getter
    // must do nothing more complicated
    final tableNameDeclaration =
        await base.loadElementDeclaration(tableNameGetter);
    final returnExpr = base.returnExpressionOfMethod(
        tableNameDeclaration.node as MethodDeclaration);

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
    final primaryKeyGetter = element.getGetter('primaryKey');
    if (primaryKeyGetter == null) {
      return null;
    }

    final resolved = await base.loadElementDeclaration(primaryKeyGetter);
    final ast = resolved.node as MethodDeclaration;
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

  Future<List<MoorColumn>> _parseColumns(ClassElement element) {
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

    return Future.wait(fields.map((field) async {
      final resolved = await base.loadElementDeclaration(field.getter);
      final node = resolved.node as MethodDeclaration;

      return await base.parseColumn(node, field.getter);
    }));
  }

  Future<List<MoorVariable>> _parseVariables(ClassElement element) {
    final variableNames = element.allSupertypes
      .map((t) => t.element)
      .followedBy([element])
      .expand((e) => e.fields)
      .where((field) {
	  	return field.metadata.singleWhere((annotation) => 
		  annotation.element != null && annotation.element.name.contains("classVariable"), 
		  orElse: () => null) != null;
	  })
      .map((field) => field.name)
      .toSet();

    final fields = variableNames.map((name) {
      final getter = element.getGetter(name) ??
          element.lookUpInheritedConcreteGetter(name, element.library);
      return getter.variable;
    });

    return Future.wait(fields.map((field) async {
      return await base.parseVariable(field);
    }));
  }
}
