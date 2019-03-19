import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:moor_generator/src/errors.dart';
import 'package:moor_generator/src/model/specified_column.dart';
import 'package:moor_generator/src/model/specified_table.dart';
import 'package:moor_generator/src/parser/parser.dart';
import 'package:moor_generator/src/sqlite_keywords.dart';
import 'package:moor_generator/src/utils/names.dart';
import 'package:moor_generator/src/utils/type_utils.dart';
import 'package:moor_generator/src/moor_generator.dart'; // ignore: implementation_imports
import 'package:recase/recase.dart';

class TableParser extends ParserBase {
  TableParser(MoorGenerator generator) : super(generator);

  SpecifiedTable parse(ClassElement element) {
    final sqlName = _parseTableName(element);
    if (sqlName == null) return null;

    final columns = _parseColumns(element);

    return SpecifiedTable(
      fromClass: element,
      columns: columns,
      sqlName: escapeIfNeeded(sqlName),
      dartTypeName: _readDartTypeName(element),
      primaryKey: _readPrimaryKey(element, columns),
    );
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

  String _parseTableName(ClassElement element) {
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
        generator.loadElementDeclaration(tableNameGetter);
    final returnExpr = returnExpressionOfMethod(
        tableNameDeclaration.node as MethodDeclaration);

    final tableName = readStringLiteral(returnExpr, () {
      generator.errors.add(MoorError(
          critical: true,
          message:
              'This getter must return a string literal, and do nothing more',
          affectedElement: tableNameGetter));
    });

    return tableName;
  }

  Set<SpecifiedColumn> _readPrimaryKey(
      ClassElement element, List<SpecifiedColumn> columns) {
    final primaryKeyGetter = element.getGetter('primaryKey');
    if (primaryKeyGetter == null) {
      return null;
    }

    final ast = generator.loadElementDeclaration(primaryKeyGetter).node
        as MethodDeclaration;
    final body = ast.body;
    if (body is! ExpressionFunctionBody) {
      generator.errors.add(MoorError(
          affectedElement: primaryKeyGetter,
          message: 'This must return a set literal using the => syntax!'));
      return null;
    }
    final expression = (body as ExpressionFunctionBody).expression;
    final parsedPrimaryKey = <SpecifiedColumn>{};

    // todo no longer support SetLiteral / MapLiteral when we can afford
    // dropping support for older analyzer versions
    if (expression is SetOrMapLiteral) {
      for (var entry in expression.elements2) {
        if (entry is Identifier) {
          final column = columns.singleWhere(
                  (column) => column.dartGetterName == entry.name);
          parsedPrimaryKey.add(column);
        } else {
          // Don't add an error, these features aren't on a stable dart release
          // yet.
          print('Unexpected entry in expression.elements2: $entry');
        }
      }
    // ignore: deprecated_member_use
    } else if (expression is MapLiteral) {
      for (var entry in expression.entries) {
        final key = entry.key as Identifier;
        final column =
        columns.singleWhere((column) => column.dartGetterName == key.name);
        parsedPrimaryKey.add(column);
      }
    // ignore: deprecated_member_use
    } else if (expression is SetLiteral) {
      for (var entry in expression.elements) {
        final column = columns.singleWhere(
                (column) => column.dartGetterName == (entry as Identifier).name);
        parsedPrimaryKey.add(column);
      }
    } else {
      generator.errors.add(MoorError(
          affectedElement: primaryKeyGetter,
          message: 'This must return a set literal!'));
    }

    return parsedPrimaryKey;
  }

  Iterable<MethodDeclaration> _findColumnGetters(ClassElement element) {
    return element.fields
        .where((field) => isColumn(field.type) && field.getter != null)
        .map((field) {
      final node = generator.loadElementDeclaration(field.getter).node;

      return node as MethodDeclaration;
    });
  }

  SpecifiedColumn _parseColumn(MethodDeclaration getter) {
    return generator.columnParser.parse(getter);
  }

  List<SpecifiedColumn> _parseColumns(ClassElement element) =>
      _findColumnGetters(element).map(_parseColumn).toList();
}
