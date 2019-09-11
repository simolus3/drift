import 'package:build/build.dart';
import 'package:moor_generator/src/analyzer/errors.dart';
import 'package:moor_generator/src/analyzer/runner/steps.dart';
import 'package:moor_generator/src/model/specified_table.dart';
import 'package:moor_generator/src/model/sql_query.dart';
import 'package:moor_generator/src/analyzer/sql_queries/query_handler.dart';
import 'package:moor_generator/src/analyzer/sql_queries/type_mapping.dart';
import 'package:sqlparser/sqlparser.dart' hide ResultColumn;

class SqlParser {
  final List<SpecifiedTable> tables;
  final AnalyzeDartStep step;
  final List<DeclaredQuery> definedQueries;

  final TypeMapper _mapper = TypeMapper();
  SqlEngine _engine;

  final List<SqlQuery> foundQueries = [];

  SqlParser(this.step, this.tables, this.definedQueries);

  void _spawnEngine() {
    _engine = SqlEngine();
    tables.map(_mapper.extractStructure).forEach(_engine.registerTable);
  }

  void parse() {
    _spawnEngine();

    for (var query in definedQueries) {
      final name = query.name;
      final sql = query.sql;

      AnalysisContext context;
      try {
        context = _engine.analyze(sql);
      } catch (e, s) {
        step.reportError(MoorError(
            severity: Severity.criticalError,
            message: 'Error while trying to parse $name: $e, $s'));
        return;
      }

      for (var error in context.errors) {
        step.reportError(MoorError(
          severity: Severity.warning,
          message: 'The sql query $name is invalid: $error',
        ));
      }

      try {
        foundQueries.add(QueryHandler(name, context, _mapper).handle());
      } catch (e, s) {
        log.warning('Error while generating APIs for $name', e, s);
      }
    }

    // report lints
    for (var query in foundQueries) {
      for (var lint in query.lints) {
        step.reportError(MoorError(
          severity: Severity.info,
          message: 'Lint for ${query.name}: $lint',
        ));
      }
    }
  }
}
