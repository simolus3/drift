import 'package:build/build.dart';
import 'package:meta/meta.dart';
import 'package:moor_generator/moor_generator.dart';
import 'package:moor_generator/src/analyzer/errors.dart';
import 'package:moor_generator/src/analyzer/runner/file_graph.dart';
import 'package:moor_generator/src/analyzer/runner/steps.dart';
import 'package:moor_generator/src/analyzer/sql_queries/lints/linter.dart';
import 'package:moor_generator/src/model/sql_query.dart';
import 'package:moor_generator/src/analyzer/sql_queries/query_handler.dart';
import 'package:moor_generator/src/analyzer/sql_queries/type_mapping.dart';
import 'package:moor_generator/src/model/view.dart';
import 'package:sqlparser/sqlparser.dart' hide ResultColumn;
import 'package:sqlparser/utils/find_referenced_tables.dart';

import 'required_variables.dart';

abstract class BaseAnalyzer {
  final List<MoorTable> tables;
  final List<MoorView> views;
  final Step step;

  @protected
  final TypeMapper mapper;
  SqlEngine? _engine;

  BaseAnalyzer(this.tables, this.views, this.step)
      : mapper = TypeMapper(
          applyTypeConvertersToVariables:
              step.task.session.options.applyConvertersOnVariables,
        );

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
  Iterable<MoorSchemaEntity> findReferences(AstNode node,
      {bool includeViews = true}) {
    final finder = ReferencedTablesVisitor();
    node.acceptWithoutArg(finder);

    var entities =
        finder.foundTables.map<MoorSchemaEntity?>(mapper.tableToMoor);
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
    if (step.file.type == FileType.moor) {
      step.reportError(
          ErrorInMoorFile.fromSqlParser(error, overrideSeverity: severity));
    } else {
      step.reportError(MoorError(
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

  SqlAnalyzer(Step step, List<MoorTable> tables, List<MoorView> views,
      this.definedQueries)
      : super(tables, views, step);

  void parse() {
    for (final query in definedQueries) {
      final name = query.name;
      var declaredInMoor = false;

      AnalysisContext? context;
      var requiredVariables = RequiredVariables.empty;

      try {
        if (query is DeclaredDartQuery) {
          final sql = query.sql;
          context = engine.analyze(sql);
        } else if (query is DeclaredMoorQuery) {
          final options = _createOptionsAndVars(query.astNode);
          requiredVariables = options.variables;

          context = engine.analyzeNode(
            query.query,
            query.file!.parseResult.sql,
            stmtOptions: options.options,
          );
          declaredInMoor = true;
        }
      } catch (e, s) {
        step.reportError(MoorError(
            severity: Severity.criticalError,
            message: 'Error while trying to parse $name: $e, $s'));
        continue;
      }

      for (final error in context!.errors) {
        report(error,
            msg: () => 'The sql query $name is invalid: $error',
            severity: Severity.error);
      }

      try {
        final handled = QueryHandler(query, context, mapper,
                requiredVariables: requiredVariables)
            .handle()
              ..declaredInMoorFile = declaredInMoor;
        foundQueries.add(handled);
      } catch (e, s) {
        // todo remove dependency on build package here
        log.warning('Error while generating APIs for $name', e, s);
      }
    }

    // report lints
    for (final query in foundQueries) {
      reportLints(query.lints ?? const <Never>[], name: query.name);
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
