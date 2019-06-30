import 'package:analyzer/dart/constant/value.dart';
import 'package:moor_generator/src/errors.dart';
import 'package:moor_generator/src/model/specified_table.dart';
import 'package:moor_generator/src/model/sql_query.dart';
import 'package:moor_generator/src/parser/sql/query_handler.dart';
import 'package:moor_generator/src/parser/sql/type_mapping.dart';
import 'package:moor_generator/src/shared_state.dart';
import 'package:sqlparser/sqlparser.dart' hide ResultColumn;

class SqlParser {
  final List<SpecifiedTable> tables;
  final SharedState state;
  final Map<DartObject, DartObject> definedQueries;

  final TypeMapper _mapper = TypeMapper();
  SqlEngine _engine;

  final List<SqlQuery> foundQueries = [];

  SqlParser(this.state, this.tables, this.definedQueries);

  void _spawnEngine() {
    _engine = SqlEngine();
    tables.map(_mapper.extractStructure).forEach(_engine.registerTable);
  }

  void parse() {
    _spawnEngine();

    definedQueries.forEach((key, value) {
      final name = key.toStringValue();
      final sql = value.toStringValue();

      AnalysisContext context;
      try {
        context = _engine.analyze(sql);
      } catch (e, s) {
        state.errors.add(MoorError(
            critical: true,
            message: 'Error while trying to parse $sql: $e, $s'));
        return;
      }

      for (var error in context.errors) {
        state.errors.add(MoorError(
          message: 'The sql query $sql is invalid: ${error.message}',
        ));
      }

      foundQueries.add(QueryHandler(name, context, _mapper).handle());
    });
  }
}
