import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:moor_generator/src/state/errors.dart';
import 'package:moor_generator/src/model/specified_column.dart';
import 'package:moor_generator/src/model/specified_table.dart';
import 'package:moor_generator/src/parser/parser.dart';
import 'package:moor_generator/src/state/session.dart';
import 'package:moor_generator/src/utils/names.dart';
import 'package:moor_generator/src/utils/type_utils.dart';
import 'package:recase/recase.dart';
import 'package:moor/sqlite_keywords.dart';

class TableParser extends ParserBase {
  TableParser(GeneratorSession session) : super(session);

  Future<SpecifiedTable> parse(ClassElement element) async {
    final sqlName = await _parseTableName(element);
    if (sqlName == null) return null;

    final columns = await _parseColumns(element);

    return SpecifiedTable(
      fromClass: element,
      columns: columns,
      sqlName: escapeIfNeeded(sqlName),
      dartTypeName: _readDartTypeName(element),
      primaryKey: await _readPrimaryKey(element, columns),
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
        await session.loadElementDeclaration(tableNameGetter);
    final returnExpr = returnExpressionOfMethod(
        tableNameDeclaration.node as MethodDeclaration);

    final tableName = readStringLiteral(returnExpr, () {
      session.errors.add(MoorError(
          critical: true,
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

    final resolved = await session.loadElementDeclaration(primaryKeyGetter);
    final ast = resolved.node as MethodDeclaration;
    final body = ast.body;
    if (body is! ExpressionFunctionBody) {
      session.errors.add(MoorError(
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
      session.errors.add(MoorError(
          affectedElement: primaryKeyGetter,
          message: 'This must return a set literal!'));
    }

    return parsedPrimaryKey;
  }

  Future<List<SpecifiedColumn>> _parseColumns(ClassElement element) {
    final columns = element.fields
        .where((field) => isColumn(field.type) && field.getter != null);

    return Future.wait(columns.map((field) async {
      final resolved = await session.loadElementDeclaration(field.getter);
      final node = resolved.node as MethodDeclaration;

      return await session.parseColumn(node, field.getter);
    }));
  }
}
