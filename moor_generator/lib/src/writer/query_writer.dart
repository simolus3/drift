import 'package:moor_generator/src/model/specified_column.dart';
import 'package:moor_generator/src/model/sql_query.dart';
import 'package:moor_generator/src/utils/string_escaper.dart';
import 'package:recase/recase.dart';
import 'package:sqlparser/sqlparser.dart';

const queryEngineWarningDesc =
    'No longer needed with Moor 1.6 - see the changelog for details';

/// Writes the handling code for a query. The code emitted will be a method that
/// should be included in a generated database or dao class.
class QueryWriter {
  final SqlQuery query;
  SqlSelectQuery get _select => query as SqlSelectQuery;
  UpdatingQuery get _update => query as UpdatingQuery;

  final Set<String> _writtenMappingMethods;

  QueryWriter(this.query, this._writtenMappingMethods);

  /// The expanded sql that we insert into queries whenever an array variable
  /// appears. For the query "SELECT * FROM t WHERE x IN ?", we generate
  /// ```dart
  /// test(List<int> var1) {
  ///   final expandedvar1 = List.filled(var1.length, '?').join(',');
  ///   customSelect('SELECT * FROM t WHERE x IN ($expandedvar1)', ...);
  /// }
  /// ```
  String _expandedName(FoundVariable v) {
    return 'expanded${v.dartParameterName}';
  }

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
    // avoid writing mapping methods twice if the same result class is written
    // more than once.
    if (!_writtenMappingMethods.contains(_nameOfMappingMethod())) {
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
      _writtenMappingMethods.add(_nameOfMappingMethod());
    }
  }

  void _writeOneTimeReader(StringBuffer buffer) {
    buffer.write('Future<List<${_select.resultClassName}>> ${query.name}(');
    _writeParameters(buffer);
    buffer.write(') {\n');
    _writeExpandedDeclarations(buffer);
    buffer
      ..write('return (operateOn ?? this).') // use custom engine, if set
      ..write('customSelect(${_queryCode()},');
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
    buffer.write(') {\n');

    _writeExpandedDeclarations(buffer);
    buffer..write('return customSelectStream(${_queryCode()},');

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
    buffer.write(') {\n');

    _writeExpandedDeclarations(buffer);
    buffer
      ..write('return (operateOn ?? this).')
      ..write('customUpdate(${_queryCode()},');

    _writeVariables(buffer);
    buffer.write(',');
    _writeUpdates(buffer);

    buffer..write(',);\n}\n');
  }

  void _writeParameters(StringBuffer buffer,
      {bool dontOverrideEngine = false}) {
    final paramList = query.variables.map((v) {
      var dartType = dartTypeNames[v.type];
      if (v.isArray) {
        dartType = 'List<$dartType>';
      }
      return '$dartType ${v.dartParameterName}';
    }).join(', ');

    buffer.write(paramList);

    // write named optional parameter to configure the query engine used to
    // execute the statement,
    if (!dontOverrideEngine) {
      if (query.variables.isNotEmpty) buffer.write(', ');
      buffer.write('{@Deprecated(${asDartLiteral(queryEngineWarningDesc)}) '
          'QueryEngine operateOn}');
    }
  }

  void _writeExpandedDeclarations(StringBuffer buffer) {
    for (var variable in query.variables) {
      if (variable.isArray) {
        // final expandedvar1 = List.filled(var1.length, '?').join(',');
        buffer
          ..write('final ')
          ..write(_expandedName(variable))
          ..write(' = ')
          ..write('List.filled(')
          ..write(variable.dartParameterName)
          ..write(".length, '?').join(',');");
      }
    }
  }

  void _writeVariables(StringBuffer buffer) {
    buffer..write('variables: [');

    for (var variable in query.variables) {
      // for a regular variable: Variable.withInt(x),
      // for a list of vars: for (var $ in vars) Variable.withInt($),
      final constructor = createVariable[variable.type];
      final name = variable.dartParameterName;

      if (variable.isArray) {
        buffer.write('for (var \$ in $name) $constructor(\$)');
      } else {
        buffer.write('$constructor($name)');
      }

      buffer.write(',');
    }

    buffer..write(']');
  }

  /// Returns a Dart string literal representing the query after variables have
  /// been expanded. For instance, 'SELECT * FROM t WHERE x IN ?' will be turned
  /// into 'SELECT * FROM t WHERE x IN ($expandedVar1)'.
  String _queryCode() {
    // sort variables by the order in which they appear
    final vars = query.fromContext.root.allDescendants
        .whereType<Variable>()
        .toList()
          ..sort((a, b) => a.firstPosition.compareTo(b.firstPosition));

    final buffer = StringBuffer("'");
    var lastIndex = 0;

    for (var sqlVar in vars) {
      final moorVar = query.variables
          .singleWhere((f) => f.variable.resolvedIndex == sqlVar.resolvedIndex);
      if (!moorVar.isArray) continue;

      // write everything that comes before this var into the buffer
      final currentIndex = sqlVar.firstPosition;
      final queryPart = query.sql.substring(lastIndex, currentIndex);
      buffer.write(escapeForDart(queryPart));
      lastIndex = sqlVar.lastPosition;

      // write the ($expandedVar) par
      buffer.write('(\$${_expandedName(moorVar)})');
    }

    // write the final part after the last variable, plus the ending '
    buffer..write(escapeForDart(query.sql.substring(lastIndex)))..write("'");

    return buffer.toString();
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
