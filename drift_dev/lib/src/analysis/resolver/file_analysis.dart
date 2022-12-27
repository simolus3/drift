import 'package:sqlparser/sqlparser.dart';

import '../../utils/entity_reference_sorter.dart';
import '../driver/driver.dart';
import '../driver/error.dart';
import '../driver/state.dart';
import '../results/file_results.dart';
import '../results/results.dart';
import 'queries/query_analyzer.dart';
import 'queries/required_variables.dart';

/// Fully resolves databases and queries after elements have been resolved.
class FileAnalyzer {
  final DriftAnalysisDriver driver;

  FileAnalyzer(this.driver);

  Future<FileAnalysisResult> runAnalysisOn(FileState state) async {
    final result = FileAnalysisResult();
    final knownTypes = await driver.loadKnownTypes();

    if (state.extension == '.dart') {
      for (final elementAnalysis in state.analysis.values) {
        final element = elementAnalysis.result;

        final queries = <String, SqlQuery>{};

        final imports = <FileState>[];

        if (element is BaseDriftAccessor) {
          for (final include in element.declaredIncludes) {
            final imported = await driver.resolveElements(driver.backend
                .resolveUri(element.declaration.sourceUri, include.toString()));

            imports.add(imported);
          }

          final imported = driver.cache.crawlMulti(imports).toSet();
          for (final import in imported) {
            await driver.resolveElements(import.ownUri);
          }

          final availableElements = imported
              .expand((reachable) {
                final elementAnalysis = reachable.analysis.values;
                return elementAnalysis.map((e) => e.result).where(
                    (e) => e is DefinedSqlQuery || e is DriftSchemaElement);
              })
              .whereType<DriftElement>()
              .followedBy(element.references)
              .transitiveClosureUnderReferences()
              .sortTopologicallyOrElse(driver.backend.log.severe);

          for (final query in element.declaredQueries) {
            final engine =
                driver.typeMapping.newEngineWithTables(availableElements);
            final context = engine.analyze(query.sql);

            final analyzer = QueryAnalyzer(context, driver,
                knownTypes: knownTypes, references: availableElements);
            queries[query.name] = analyzer.analyze(query);

            for (final error in analyzer.lints) {
              result.analysisErrors.add(DriftAnalysisError.fromSqlError(error));
            }
          }

          result.resolvedDatabases[element.id] =
              ResolvedDatabaseAccessor(queries, imports, availableElements);
        }
      }
    } else if (state.extension == '.drift' || state.extension == '.moor') {
      // We need to map defined query elements to proper analysis results.
      final genericEngineForParsing = driver.newSqlEngine();
      final source = await driver.backend.readAsString(state.ownUri);
      final parsedFile =
          genericEngineForParsing.parseDriftFile(source).rootNode as DriftFile;

      for (final elementAnalysis in state.analysis.values) {
        final element = elementAnalysis.result;
        if (element is DefinedSqlQuery) {
          final engine =
              driver.typeMapping.newEngineWithTables(element.references);
          final stmt = parsedFile.statements
              .whereType<DeclaredStatement>()
              .firstWhere(
                  (e) => e.statement.firstPosition == element.sqlOffset);
          // Necessary to create options when type hints for indexed variables
          // are given.
          AstPreparingVisitor.resolveIndexOfVariables(
              stmt.allDescendants.whereType<Variable>().toList());

          final options = _createOptionsAndVars(engine, stmt);

          final analysisResult = engine.analyzeNode(stmt.statement, source,
              stmtOptions: options.options);

          final analyzer = QueryAnalyzer(analysisResult, driver,
              knownTypes: knownTypes,
              references: element.references,
              requiredVariables: options.variables);

          result.resolvedQueries[element.id] = analyzer.analyze(element,
              sourceForCustomName: stmt.as)
            ..declaredInDriftFile = true;

          for (final error in analyzer.lints) {
            result.analysisErrors.add(DriftAnalysisError.fromSqlError(error));
          }
        } else if (element is DriftView) {
          final source = element.source;
          if (source is SqlViewSource) {
            source.parsedStatement =
                parsedFile.findStatement(element.declaration);
          }
        } else if (element is DriftTrigger) {
          element.parsedStatement =
              parsedFile.findStatement(element.declaration);
        } else if (element is DriftIndex) {
          element.parsedStatement =
              parsedFile.findStatement(element.declaration);
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

extension on DriftFile {
  Node findStatement<Node extends AstNode>(DriftDeclaration declaration) {
    return statements
        .whereType<Node>()
        .firstWhere((e) => e.firstPosition == declaration.offset);
  }
}
