//@dart=2.9
part of '../steps.dart';

/// Analyzes the compiled queries found in a Dart file.
class AnalyzeDartStep extends AnalyzingStep {
  AnalyzeDartStep(Task task, FoundFile file) : super(task, file);

  void analyze() {
    final parseResult = file.currentResult as ParsedDartFile;

    for (final accessor in parseResult.dbAccessors) {
      final transitiveImports = task.crawlImports(accessor.imports).toList();

      final unsortedEntities = _availableEntities(transitiveImports).toSet();

      final tableDartClasses = unsortedEntities.map((e) {
        final declaration = e.declaration;
        if (declaration is DartTableDeclaration) {
          return declaration.element;
        }
        return null;
      }).where((element) => element != null);

      for (final declaredHere in accessor.declaredTables) {
        // See issue #447: The table added to an accessor might already be
        // included through a transitive moor file. In that case, we just ignore
        // it to avoid duplicates.
        final declaration = declaredHere.declaration;
        if (declaration is DartTableDeclaration &&
            tableDartClasses.contains(declaration.element)) {
          continue;
        }

        // Not a Dart table that we already included - add it now
        unsortedEntities.add(declaredHere);
      }

      List<MoorSchemaEntity> availableEntities;

      try {
        availableEntities = sortEntitiesTopologically(unsortedEntities);
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
      } on Exception catch (e) {
        // unknown error while sorting
        reportError(ErrorInDartCode(
          severity: Severity.warning,
          affectedElement: accessor.fromClass,
          message: 'Unknown error while sorting database entities: $e',
        ));
      }

      // Just to have something in case the above breaks.
      availableEntities ??= const [];

      final availableQueries = transitiveImports
          .map((f) => f.currentResult)
          .whereType<ParsedMoorFile>()
          .expand((f) => f.resolvedQueries);

      final availableTables = availableEntities.whereType<MoorTable>().toList();
      final availableViews = availableEntities.whereType<MoorView>().toList();
      final parser = SqlAnalyzer(
          this, availableTables, availableViews, accessor.declaredQueries);
      parser.parse();

      accessor
        ..entities = availableEntities
        ..queries = availableQueries.followedBy(parser.foundQueries).toList();

      // Support custom result class names.
      CustomResultClassTransformer(accessor).transform(errors);
    }
  }
}
