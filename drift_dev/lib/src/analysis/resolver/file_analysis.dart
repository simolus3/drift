import 'package:sqlparser/sqlparser.dart';

import '../driver/driver.dart';
import '../driver/error.dart';
import '../driver/state.dart';
import '../results/file_results.dart';
import '../results/results.dart';
import 'queries/query_analyzer.dart';
import 'queries/required_variables.dart';

class FileAnalyzer {
  final DriftAnalysisDriver driver;

  FileAnalyzer(this.driver);

  Future<FileAnalysisResult> runAnalysisOn(FileState state) async {
    final result = FileAnalysisResult();

    if (state.extension == '.dart') {
      for (final elementAnalysis in state.analysis.values) {
        final element = elementAnalysis.result;

        final queries = <String, SqlQuery>{};

        if (element is BaseDriftAccessor) {
          for (final query in element.declaredQueries) {
            final engine =
                driver.typeMapping.newEngineWithTables(element.references);
            final context = engine.analyze(query.sql);

            final analyzer = QueryAnalyzer(context, driver,
                references: element.references.toList());
            queries[query.name] = analyzer.analyze(query);

            for (final error in analyzer.lints) {
              result.analysisErrors.add(DriftAnalysisError(
                  error.span, 'Error in ${query.name}: ${error.message}'));
            }
          }
        }
      }
    } else if (state.extension == '.drift' || state.extension == '.moor') {
      // We need to map defined query elements to proper analysis results.
      final genericEngineForParsing = driver.newSqlEngine();
      final source = await driver.backend.readAsString(state.ownUri);
      final parsedFile =
          genericEngineForParsing.parse(source).rootNode as DriftFile;

      for (final elementAnalysis in state.analysis.values) {
        final element = elementAnalysis.result;
        if (element is DefinedSqlQuery) {
          final engine =
              driver.typeMapping.newEngineWithTables(element.references);
          final stmt = parsedFile.statements
                  .firstWhere((e) => e.firstPosition == element.sqlOffset)
              as DeclaredStatement;
          final options = _createOptionsAndVars(engine, stmt);

          final analysisResult =
              engine.analyzeNode(stmt, source, stmtOptions: options.options);

          final analyzer = QueryAnalyzer(analysisResult, driver,
              references: element.references,
              requiredVariables: options.variables);

          result.resolvedQueries[element.id] = analyzer.analyze(element)
            ..declaredInDriftFile = true;

          for (final error in analyzer.lints) {
            result.analysisErrors
                .add(DriftAnalysisError(error.span, error.message ?? ''));
          }
        }
      }
    }

    return result;
  }

  _OptionsAndRequiredVariables _createOptionsAndVars(
      SqlEngine engine, DeclaredStatement stmt) {
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
