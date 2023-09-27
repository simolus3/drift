import 'package:sqlparser/sqlparser.dart';

import '../../utils/entity_reference_sorter.dart';
import '../driver/driver.dart';
import '../driver/error.dart';
import '../driver/state.dart';
import '../results/file_results.dart';
import '../results/results.dart';
import 'dart/helper.dart';
import 'drift/sqlparser/mapping.dart';
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

          final availableByDefault = <DriftSchemaElement>{
            ...element.declaredTables,
            ...element.declaredViews,
          };

          // For indices added to tables via an annotation, the index should
          // also be available.
          for (final table in element.declaredTables) {
            final fileState = driver.cache.knownFiles[table.id.libraryUri]!;

            for (final attachedIndex in table.attachedIndices) {
              final index = await driver.resolveElement(
                  fileState, fileState.id(attachedIndex));

              if (index is DriftIndex) {
                availableByDefault.add(index);
              }
            }
          }

          final availableElements = imported
              .expand((reachable) {
                final elementAnalysis = reachable.analysis.values;

                return elementAnalysis.map((e) => e.result).where(
                    (e) => e is DefinedSqlQuery || e is DriftSchemaElement);
              })
              .whereType<DriftElement>()
              .followedBy(availableByDefault)
              .transitiveClosureUnderReferences()
              .sortTopologicallyOrElse(driver.backend.log.severe);

          // We will generate code for all available elements - even those only
          // reachable through imports. If that means we're pulling in a table
          // from a Dart file that hasn't been added to `tables`, emit a warning.
          // https://github.com/simolus3/drift/issues/2462#issuecomment-1620107751
          if (element is DriftDatabase) {
            final implicitlyAdded = availableElements
                .whereType<DriftElementWithResultSet>()
                .where((element) =>
                    element.declaration.isDartDeclaration &&
                    !availableByDefault.contains(element));

            if (implicitlyAdded.isNotEmpty) {
              final names = implicitlyAdded
                  .map((e) => e.definingDartClass?.toString() ?? e.schemaName)
                  .join(', ');

              driver.backend.log.warning(
                'Due to includes added to the database, the following Dart '
                'tables which have not been added to `tables` or `views` will '
                'be included in this database: $names',
              );
            }
          }

          for (final query in element.declaredQueries) {
            final engine =
                driver.typeMapping.newEngineWithTables(availableElements);
            final context = engine.analyze(query.sql);

            final analyzer = QueryAnalyzer(context, state, driver,
                knownTypes: knownTypes, references: availableElements);
            queries[query.name] = await analyzer.analyze(query);

            for (final error in analyzer.lints) {
              result.analysisErrors.add(DriftAnalysisError.fromSqlError(error));
            }
          }

          result.resolvedDatabases[element.id] =
              ResolvedDatabaseAccessor(queries, imports, availableElements);
        } else if (element is DriftIndex) {
          // We need the SQL AST for each index to create them in code
          element.createStatementForDartDefinition();
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

          final options =
              _createOptionsAndVars(engine, stmt, element, knownTypes);

          final analysisResult = engine.analyzeNode(stmt.statement, source,
              stmtOptions: options.options);

          final analyzer = QueryAnalyzer(analysisResult, state, driver,
              knownTypes: knownTypes,
              references: element.references,
              requiredVariables: options.variables);

          result.resolvedQueries[element.id] =
              await analyzer.analyze(element, sourceForCustomName: stmt.as)
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
    SqlEngine engine,
    DeclaredStatement stmt,
    DefinedSqlQuery query,
    KnownDriftTypes helper,
  ) {
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
        resolveTypeFromText: enumColumnFromText(query.dartTypes, helper),
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
