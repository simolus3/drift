import 'package:analyzer/dart/constant/value.dart';
import 'package:build/build.dart';
import 'package:moor_generator/src/state/errors.dart';
import 'package:moor_generator/src/model/specified_table.dart';
import 'package:moor_generator/src/model/sql_query.dart';
import 'package:moor_generator/src/parser/sql/query_handler.dart';
import 'package:moor_generator/src/parser/sql/type_mapping.dart';
import 'package:moor_generator/src/state/session.dart';
import 'package:sqlparser/sqlparser.dart' hide ResultColumn;

class SqlParser {
  final List<SpecifiedTable> tables;
  final GeneratorSession session;
  final Map<DartObject, DartObject> definedQueries;

  final TypeMapper _mapper = TypeMapper();
  SqlEngine _engine;

  final List<SqlQuery> foundQueries = [];

  SqlParser(this.session, this.tables, this.definedQueries);

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
        session.errors.add(MoorError(
            critical: true,
            message: 'Error while trying to parse $sql: $e, $s'));
        return;
      }

      for (var error in context.errors) {
        session.errors.add(MoorError(
          message: 'The sql query $sql is invalid: $error',
        ));
      }

      try {
        foundQueries.add(QueryHandler(name, context, _mapper).handle());
      } catch (e, s) {
        log.warning('Error while generating APIs for ${context.sql}', e, s);
      }
    });

    // report lints
    for (var query in foundQueries) {
      for (var lint in query.lints) {
        session.errors.add(MoorError(
          critical: false,
          message: 'Lint for ${query.name}: $lint',
        ));
      }
    }
  }
}
