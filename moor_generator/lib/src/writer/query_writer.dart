import 'package:moor_generator/src/model/specified_column.dart';
import 'package:moor_generator/src/model/sql_query.dart';
import 'package:moor_generator/src/utils/string_escaper.dart';
import 'package:recase/recase.dart';

/// Writes the handling code for a query. The code emitted will be a method that
/// should be included in a generated database or dao class.
class QueryWriter {
  final SqlQuery query;
  SqlSelectQuery get _select => query as SqlSelectQuery;

  QueryWriter(this.query);

  /* The generated code will look like:
    Future<List<AllTodosWithCategoryResult>> allTodosWithCategory() {
    return customSelect('', variables: [])
        .then((rows) => rows.map(_rowToAllT).toList());
  }

  Stream<List<AllTodosWithCategoryResult>> watchAllTodosWithCategory() {
    return customSelectStream('', variables: [])
        .map((rows) => rows.map(_rowToAllT).toList());
  }

  AllTodosWithCategoryResult _rowToAllT(QueryRow row) {
    return AllTodosWithCategoryResult(
      id: row.readInt('id'),
    );
  }
   */

  void writeInto(StringBuffer buffer) {
    if (query is SqlSelectQuery) {
      _writeSelect(buffer);
    }
  }

  void _writeSelect(StringBuffer buffer) {
    _writeMapping(buffer);
    _writeOneTimeReader(buffer);
    _writeStreamReader(buffer);
  }

  String _nameOfMappingMethod() {
    return '_rowTo${_select.resultClassName}';
  }

  /// Writes a mapping method that turns a "QueryRow" into the desired custom
  /// return type.
  void _writeMapping(StringBuffer buffer) {
    buffer
      ..write('${_select.resultClassName} ${_nameOfMappingMethod()}')
      ..write('(QueryRow row) {\n')
      ..write('return ${_select.resultClassName}(');

    for (var column in _select.resultSet.columns) {
      final fieldName = _select.resultSet.dartNameFor(column);
      final readMethod = readFromMethods[column.type];
      buffer.write("$fieldName: row.$readMethod('${column.name}'),");
    }

    buffer.write(');\n}\n');
  }

  void _writeOneTimeReader(StringBuffer buffer) {
    buffer
      ..write('Future<List<${_select.resultClassName}>> ${query.name}() {\n')
      ..write('return customSelect(${asDartLiteral(query.sql)})')
      ..write(
          '.then((rows) => rows.map(${_nameOfMappingMethod()}).toList());\n')
      ..write('\n}\n');
  }

  void _writeStreamReader(StringBuffer buffer) {
    final upperQueryName = ReCase(query.name).pascalCase;
    buffer
      ..write('Stream<List<${_select.resultClassName}>> watch$upperQueryName')
      ..write('() {\n')
      ..write('return customSelectStream(${asDartLiteral(query.sql)})')
      ..write('.map((rows) => rows.map(${_nameOfMappingMethod()}).toList());\n')
      ..write('\n}\n');
  }
}
