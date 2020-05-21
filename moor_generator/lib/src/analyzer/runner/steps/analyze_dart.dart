part of '../steps.dart';

/// Analyzes the compiled queries found in a Dart file.
class AnalyzeDartStep extends AnalyzingStep {
  AnalyzeDartStep(Task task, FoundFile file) : super(task, file);

  void analyze() {
    final parseResult = file.currentResult as ParsedDartFile;

    for (final accessor in parseResult.dbAccessors) {
      final transitiveImports = _transitiveImports(accessor.imports);

      final unsortedEntities = _availableEntities(transitiveImports)
          .followedBy(accessor.declaredTables);
      List<MoorSchemaEntity> availableEntities;

      try {
        availableEntities = sortEntitiesTopologically(unsortedEntities.toSet());
      } on CircularReferenceException catch (e) {
        // Just keep them unsorted so that we can generate some code
        availableEntities = unsortedEntities.toList();
        final msg = StringBuffer(
            'Found a circular reference in your database. This can cause '
            'exceptions at runtime when opening the database. This is the '
            'cycle that we found: ');

        msg.write(e.affected.map((t) => t.displayName).join(' -> '));
        // the last table in e.affected references the first one. Let's make
        // that clear in the visualization.
        msg.write(' -> ${e.affected.first.displayName}');

        reportError(ErrorInDartCode(
          severity: Severity.warning,
          affectedElement: accessor.fromClass,
          message: msg.toString(),
        ));
      } catch (e) {
        // unknown error while sorting
        reportError(ErrorInDartCode(
          severity: Severity.warning,
          affectedElement: accessor.fromClass,
          message: 'Unknown error while sorting database entities: $e',
        ));
      }

      final availableQueries = transitiveImports
          .map((f) => f.currentResult)
          .whereType<ParsedMoorFile>()
          .expand((f) => f.resolvedQueries);

      final availableTables = availableEntities.whereType<MoorTable>().toList();
      final parser =
          SqlAnalyzer(this, availableTables, accessor.declaredQueries);
      parser.parse();

      accessor
        ..entities = availableEntities
        ..queries = availableQueries.followedBy(parser.foundQueries).toList();

      // Support custom result class names.
      CustomResultClassTransformer(accessor).transform(this);
    }
  }
}
