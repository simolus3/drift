import 'package:moor_generator/src/model/specified_column.dart';
import 'package:moor_generator/src/model/sql_query.dart';
import 'package:moor_generator/src/utils/string_escaper.dart';
import 'package:recase/recase.dart';

/// Writes the handling code for a query. The code emitted will be a method that
/// should be included in a generated database or dao class.
class QueryWriter {
  final SqlQuery query;
  SqlSelectQuery get _select => query as SqlSelectQuery;
  UpdatingQuery get _update => query as UpdatingQuery;

  QueryWriter(this.query);

  void writeInto(StringBuffer buffer) {
    if (query is SqlSelectQuery) {
      _writeSelect(buffer);
    } else if (query is UpdatingQuery) {
      _writeUpdatingQuery(buffer);
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
    buffer.write('Future<List<${_select.resultClassName}>> ${query.name}(');
    _writeParameters(buffer);
    buffer
      ..write(') {\n')
      ..write('return (operateOn ?? this).') // use custom engine, if set
      ..write('customSelect(${asDartLiteral(query.sql)},');
    _writeVariables(buffer);
    buffer
      ..write(')')
      ..write(
          '.then((rows) => rows.map(${_nameOfMappingMethod()}).toList());\n')
      ..write('\n}\n');
  }

  void _writeStreamReader(StringBuffer buffer) {
    final upperQueryName = ReCase(query.name).pascalCase;
    buffer.write(
        'Stream<List<${_select.resultClassName}>> watch$upperQueryName(');
    // don't supply an engine override parameter because select streams cannot
    // be used in transaction or similar context, only on the main database
    // engine.
    _writeParameters(buffer, dontOverrideEngine: true);
    buffer
      ..write(') {\n')
      ..write('return customSelectStream(${asDartLiteral(query.sql)},');

    _writeVariables(buffer);
    buffer.write(',');
    _writeReadsFrom(buffer);

    buffer
      ..write(')')
      ..write('.map((rows) => rows.map(${_nameOfMappingMethod()}).toList());\n')
      ..write('\n}\n');
  }

  void _writeUpdatingQuery(StringBuffer buffer) {
    /*
      Future<int> test() {
    return customUpdate('', variables: [], updates: {});
  }
     */
    buffer.write('Future<int> ${query.name}(');
    _writeParameters(buffer);
    buffer
      ..write(') {\n')
      ..write('return (operateOn ?? this).')
      ..write('customUpdate(${asDartLiteral(query.sql)},');

    _writeVariables(buffer);
    buffer.write(',');
    _writeUpdates(buffer);

    buffer..write(');\n}\n');
  }

  void _writeParameters(StringBuffer buffer,
      {bool dontOverrideEngine = false}) {
    final paramList = query.variables
        .map((v) => '${dartTypeNames[v.type]} ${v.dartParameterName}')
        .join(', ');

    buffer.write(paramList);

    // write named optional parameter to configure the query engine used to
    // execute the statement,
    if (!dontOverrideEngine) {
      if (query.variables.isNotEmpty) buffer.write(', ');
      buffer.write('{QueryEngine operateOn}');
    }
  }

  void _writeVariables(StringBuffer buffer) {
    buffer..write('variables: [');

    for (var variable in query.variables) {
      buffer
        ..write(createVariable[variable.type])
        ..write('(${variable.dartParameterName}),');
    }

    buffer..write(']');
  }

  void _writeReadsFrom(StringBuffer buffer) {
    final from = _select.readsFrom.map((t) => t.tableFieldName).join(', ');
    buffer..write('readsFrom: {')..write(from)..write('}');
  }

  void _writeUpdates(StringBuffer buffer) {
    final from = _update.updates.map((t) => t.tableFieldName).join(', ');
    buffer..write('updates: {')..write(from)..write('}');
  }
}
