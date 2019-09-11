part of 'parser.dart';

/// Parses a [SpecifiedTable] from a Dart class.
class TableParser {
  final MoorDartParser base;

  TableParser(this.base);

  Future<SpecifiedTable> parseTable(ClassElement element) async {
    final sqlName = await _parseTableName(element);
    if (sqlName == null) return null;

    final columns = await _parseColumns(element);

    final table = SpecifiedTable(
      fromClass: element,
      columns: columns,
      sqlName: escapeIfNeeded(sqlName),
      dartTypeName: _readDartTypeName(element),
      primaryKey: await _readPrimaryKey(element, columns),
    );

    var index = 0;
    for (var converter in table.converters) {
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

  Future<Set<SpecifiedColumn>> _readPrimaryKey(
      ClassElement element, List<SpecifiedColumn> columns) async {
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
    final parsedPrimaryKey = <SpecifiedColumn>{};

    if (expression is SetOrMapLiteral) {
      for (var entry in expression.elements) {
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

  Future<List<SpecifiedColumn>> _parseColumns(ClassElement element) {
    final columns = element.fields
        .where((field) => isColumn(field.type) && field.getter != null);

    return Future.wait(columns.map((field) async {
      final resolved = await base.loadElementDeclaration(field.getter);
      final node = resolved.node as MethodDeclaration;

      return await base.parseColumn(node, field.getter);
    }));
  }
}
