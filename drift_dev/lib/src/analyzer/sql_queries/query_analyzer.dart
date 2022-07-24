import 'package:build/build.dart';
import 'package:drift_dev/moor_generator.dart';
import 'package:drift_dev/src/analyzer/errors.dart';
import 'package:drift_dev/src/analyzer/runner/file_graph.dart';
import 'package:drift_dev/src/analyzer/runner/steps.dart';
import 'package:drift_dev/src/analyzer/sql_queries/lints/linter.dart';
import 'package:drift_dev/src/analyzer/sql_queries/query_handler.dart';
import 'package:drift_dev/src/analyzer/sql_queries/type_mapping.dart';
import 'package:meta/meta.dart';
import 'package:sqlparser/sqlparser.dart' hide ResultColumn;
import 'package:sqlparser/utils/find_referenced_tables.dart';

import 'required_variables.dart';

abstract class BaseAnalyzer {
  final List<DriftTable> tables;
  final List<MoorView> views;
  final Step step;

  @protected
  final TypeMapper mapper;
  SqlEngine? _engine;

  BaseAnalyzer(this.tables, this.views, this.step)
      : mapper = TypeMapper(options: step.task.session.options);

  @protected
  SqlEngine get engine {
    if (_engine == null) {
      final engine = _engine = step.task.session.spawnEngine();
      tables.map(mapper.extractStructure).forEach(engine.registerTable);
      views.map(mapper.extractView).forEach(engine.registerView);
    }
    return _engine!;
  }

  @protected
  Iterable<DriftSchemaEntity> findReferences(AstNode node,
      {bool includeViews = true}) {
    final finder = ReferencedTablesVisitor();
    node.acceptWithoutArg(finder);

    var entities =
        finder.foundTables.map<DriftSchemaEntity?>(mapper.tableToMoor);
    if (includeViews) {
      entities = entities.followedBy(finder.foundViews.map(mapper.viewToMoor));
    }

    return entities.whereType();
  }

  @protected
  void lintContext(AnalysisContext context, String displayName) {
    context.errors.forEach(report);

    // Additional, moor-specific analysis
    final linter = Linter(context, mapper);
    linter.reportLints();
    reportLints(linter.lints, name: displayName);
  }

  @protected
  void report(AnalysisError error,
      {String Function()? msg, Severity? severity}) {
    if (step.file.type == FileType.drift) {
      step.reportError(
          ErrorInDriftFile.fromSqlParser(error, overrideSeverity: severity));
    } else {
      step.reportError(DriftError(
        severity: severity!,
        message: msg!(),
      ));
    }
  }

  @protected
  void reportLints(List<AnalysisError> lints, {String? name}) {
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

  SqlAnalyzer(Step step, List<DriftTable> tables, List<MoorView> views,
      this.definedQueries)
      : super(tables, views, step);

  void parse() {
    for (final query in definedQueries) {
      final name = query.name;

      AnalysisContext? context;
      var requiredVariables = RequiredVariables.empty;

      try {
        if (query is DeclaredDartQuery) {
          final sql = query.sql;
          context = engine.analyze(sql);
        } else if (query is DeclaredMoorQuery) {
          final options = _createOptionsAndVars(query.astNode);
          final statements = query.query;

          if (statements.length > 1) {
            _handleMultiStatementQuery(query, statements, options);
            continue;
          } else {
            requiredVariables = options.variables;
            context = engine.analyzeNode(
              statements.single,
              query.file!.parseResult.sql,
              stmtOptions: options.options,
            );
          }
        }
      } catch (e, s) {
        step.reportError(DriftError(
            severity: Severity.criticalError,
            message: 'Error while trying to parse $name: $e, $s'));
        continue;
      }

      _handleQuery(query, context!, mapper, requiredVariables);
    }

    // report lints
    for (final query in foundQueries) {
      reportLints(query.lints ?? const <Never>[], name: query.name);
    }
  }

  void _handleMultiStatementQuery(
    DeclaredMoorQuery query,
    Iterable<CrudStatement> statements,
    _OptionsAndRequiredVariables options,
  ) {
    for (final stmt in statements) {
      final context = engine.analyzeNode(
        stmt,
        query.file!.parseResult.sql,
        stmtOptions: options.options,
      );

      _handleQuery(query, context, mapper, options.variables);
    }
  }

  void _handleQuery(DeclaredQuery query, AnalysisContext context,
      TypeMapper mapper, RequiredVariables variables) {
    final name = query.name;
    for (final error in context.errors) {
      report(error,
          msg: () => 'The sql query $name is invalid: $error',
          severity: Severity.error);
    }

    try {
      final handled =
          QueryHandler(context, mapper, requiredVariables: variables)
              .handle(query)
            ..declaredInMoorFile = query is DeclaredMoorQuery;
      foundQueries.add(handled);
    } catch (e, s) {
      // todo remove dependency on build package here
      log.warning('Error while generating APIs for $name', e, s);
    }
  }

  _OptionsAndRequiredVariables _createOptionsAndVars(DeclaredStatement stmt) {
    final reader = engine.schemaReader;
    final indexedHints = <int, ResolvedType>{};
    final namedHints = <String, ResolvedType>{};
    final defaultValues = <String, Expression>{};
    final requiredIndex = <int>{};
    final requiredName = <String>{};

    for (final parameter in stmt.parameters) {
      if (parameter is VariableTypeHint) {
        final variable = parameter.variable;

        if (parameter.isRequired) {
          if (variable is ColonNamedVariable) {
            requiredName.add(variable.name);
          } else if (variable is NumberedVariable) {
            requiredIndex.add(variable.resolvedIndex!);
          }
        }

        if (parameter.typeName != null) {
          final type = reader
              .resolveColumnType(parameter.typeName)
              .withNullable(parameter.orNull);

          if (variable is ColonNamedVariable) {
            namedHints[variable.name] = type;
          } else if (variable is NumberedVariable) {
            indexedHints[variable.resolvedIndex!] = type;
          }
        }
      } else if (parameter is DartPlaceholderDefaultValue) {
        defaultValues[parameter.variableName] = parameter.defaultValue;
      }
    }

    return _OptionsAndRequiredVariables(
      AnalyzeStatementOptions(
        indexedVariableTypes: indexedHints,
        namedVariableTypes: namedHints,
        defaultValuesForPlaceholder: defaultValues,
      ),
      RequiredVariables(requiredIndex, requiredName),
    );
  }
}

class _OptionsAndRequiredVariables {
  final AnalyzeStatementOptions options;
  final RequiredVariables variables;

  _OptionsAndRequiredVariables(this.options, this.variables);
}
