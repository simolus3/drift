import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:sally_generator/src/errors.dart';
import 'package:sally_generator/src/model/specified_column.dart';
import 'package:sally_generator/src/model/specified_table.dart';
import 'package:sally_generator/src/parser/parser.dart';
import 'package:sally_generator/src/utils/type_utils.dart';
import 'package:sally_generator/src/sally_generator.dart'; // ignore: implementation_imports
import 'package:recase/recase.dart';

class TableParser extends ParserBase {
  TableParser(SallyGenerator generator) : super(generator);

  SpecifiedTable parse(ClassElement element) {
    String sqlName = _parseTableName(element);

    return SpecifiedTable(
        fromClass: element,
        columns: _parseColumns(element),
        sqlName: sqlName,
        dartTypeName:
            "${element.name}_Data" // TODO better name for generated data classes
        );
  }

  String _parseTableName(ClassElement element) {
    final tableNameGetter = element.getGetter("tableName");
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

    String tableName = readStringLiteral(returnExpr, () {
      generator.errors.add(SallyError(
          critical: true,
          message:
              "This getter must return a string literal, and do nothing more",
          affectedElement: tableNameGetter));
    });

    return tableName;
  }

  Iterable<MethodDeclaration> _findColumnGetters(ClassElement element) {
    return element.fields
        .where((field) => isColumn(field.type) && field.getter != null)
        .map((field) {
      var node = generator.loadElementDeclaration(field.getter).node;

      return node as MethodDeclaration;
    });
  }

  SpecifiedColumn _parseColumn(MethodDeclaration getter) {
    return generator.columnParser.parse(getter);
  }

  List<SpecifiedColumn> _parseColumns(ClassElement element) =>
      _findColumnGetters(element).map(_parseColumn).toList();
}
