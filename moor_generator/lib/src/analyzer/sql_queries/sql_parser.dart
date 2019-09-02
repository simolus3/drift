import 'package:analyzer/dart/constant/value.dart';
import 'package:build/build.dart';
import 'package:moor_generator/src/analyzer/errors.dart';
import 'package:moor_generator/src/analyzer/session.dart';
import 'package:moor_generator/src/model/specified_table.dart';
import 'package:moor_generator/src/model/sql_query.dart';
import 'package:moor_generator/src/analyzer/sql_queries/query_handler.dart';
import 'package:moor_generator/src/analyzer/sql_queries/type_mapping.dart';
import 'package:sqlparser/sqlparser.dart' hide ResultColumn;

class SqlParser {
  final List<SpecifiedTable> tables;
  final FileTask task;
  final Map<DartObject, DartObject> definedQueries;

  final TypeMapper _mapper = TypeMapper();
  SqlEngine _engine;

  final List<SqlQuery> foundQueries = [];

  SqlParser(this.task, this.tables, this.definedQueries);

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
        task.reportError(MoorError(
            severity: Severity.criticalError,
            message: 'Error while trying to parse $sql: $e, $s'));
        return;
      }

      for (var error in context.errors) {
        task.reportError(MoorError(
          severity: Severity.warning,
          message: 'The sql query $sql is invalid: $error',
        ));
      }

      try {
        foundQueries.add(QueryHandler(name, context, _mapper).handle());
      } catch (e, s) {
        log.warning('Error while generating APIs for ${context.sql}', e, s);
      }
    });
  }
}
