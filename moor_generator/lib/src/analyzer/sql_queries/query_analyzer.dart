import 'package:build/build.dart';
import 'package:meta/meta.dart';
import 'package:moor_generator/moor_generator.dart';
import 'package:moor_generator/src/analyzer/errors.dart';
import 'package:moor_generator/src/analyzer/runner/file_graph.dart';
import 'package:moor_generator/src/analyzer/runner/steps.dart';
import 'package:moor_generator/src/model/sql_query.dart';
import 'package:moor_generator/src/analyzer/sql_queries/query_handler.dart';
import 'package:moor_generator/src/analyzer/sql_queries/type_mapping.dart';
import 'package:sqlparser/sqlparser.dart' hide ResultColumn;

abstract class BaseAnalyzer {
  final List<MoorTable> tables;
  final Step step;

  @protected
  final TypeMapper mapper = TypeMapper();
  SqlEngine _engine;

  BaseAnalyzer(this.tables, this.step);

  @protected
  SqlEngine get engine {
    if (_engine == null) {
      _engine = step.task.session.spawnEngine();
      tables.map(mapper.extractStructure).forEach(_engine.registerTable);
    }
    return _engine;
  }

  @protected
  void report(AnalysisError error, {String Function() msg, Severity severity}) {
    if (step.file.type == FileType.moor) {
      step.reportError(
          ErrorInMoorFile.fromSqlParser(error, overrideSeverity: severity));
    } else {
      step.reportError(MoorError(
        severity: severity,
        message: msg(),
      ));
    }
  }

  @protected
  void reportLints(List<AnalysisError> lints, {String name}) {
    for (final lint in lints) {
      report(
        lint,
        msg: () => 'Lint for $name: $lint',
        severity: Severity.warning,
      );
    }
  }
}

class SqlAnalyzer extends BaseAnalyzer {
  final List<DeclaredQuery> definedQueries;

  final List<SqlQuery> foundQueries = [];

  SqlAnalyzer(Step step, List<MoorTable> tables, this.definedQueries)
      : super(tables, step);

  void parse() {
    for (final query in definedQueries) {
      final name = query.name;
      var declaredInMoor = false;

      AnalysisContext context;

      try {
        if (query is DeclaredDartQuery) {
          final sql = query.sql;
          context = engine.analyze(sql);
        } else if (query is DeclaredMoorQuery) {
          context = engine.analyzeNode(
            query.query,
            query.file.parseResult.sql,
            stmtOptions: _createOptions(query.astNode),
          );
          declaredInMoor = true;
        }
      } catch (e, s) {
        step.reportError(MoorError(
            severity: Severity.criticalError,
            message: 'Error while trying to parse $name: $e, $s'));
        continue;
      }

      for (final error in context.errors) {
        report(error,
            msg: () => 'The sql query $name is invalid: $error',
            severity: Severity.error);
      }

      try {
        final handled = QueryHandler(query, context, mapper).handle()
          ..declaredInMoorFile = declaredInMoor;
        foundQueries.add(handled);
      } catch (e, s) {
        // todo remove dependency on build package here
        log.warning('Error while generating APIs for $name', e, s);
      }
    }

    // report lints
    for (final query in foundQueries) {
      reportLints(query.lints, name: query.name);
    }
  }

  AnalyzeStatementOptions _createOptions(DeclaredStatement stmt) {
    final reader = engine.schemaReader;
    final indexedHints = <int, ResolvedType>{};
    final namedHints = <String, ResolvedType>{};

    for (final hint in stmt.parameters.whereType<VariableTypeHint>()) {
      final variable = hint.variable;
      final type = reader.resolveColumnType(hint.typeName);

      if (variable is ColonNamedVariable) {
        namedHints[variable.name] = type;
      } else if (variable is NumberedVariable) {
        indexedHints[variable.resolvedIndex] = type;
      }
    }

    return AnalyzeStatementOptions(
      indexedVariableTypes: indexedHints,
      namedVariableTypes: namedHints,
    );
  }
}
