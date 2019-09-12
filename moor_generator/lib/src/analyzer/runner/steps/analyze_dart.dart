part of '../steps.dart';

/// Analyzes the compiled queries found in a Dart file.
class AnalyzeDartStep extends AnalyzingStep {
  AnalyzeDartStep(Task task, FoundFile file) : super(task, file);

  void analyze() {
    final parseResult = file.currentResult as ParsedDartFile;

    for (var accessor in parseResult.dbAccessors) {
      final transitiveImports = _transitiveImports(accessor.resolvedImports);

      final availableTables = _availableTables(transitiveImports)
          .followedBy(accessor.tables)
          .toList();

      final availableQueries = transitiveImports
          .map((f) => f.currentResult)
          .whereType<ParsedMoorFile>()
          .expand((f) => f.resolvedQueries);

      final parser = SqlParser(this, availableTables, accessor.queries);
      parser.parse();

      accessor.allTables = availableTables;

      accessor.resolvedQueries =
          availableQueries.followedBy(parser.foundQueries).toList();
    }
  }
}
