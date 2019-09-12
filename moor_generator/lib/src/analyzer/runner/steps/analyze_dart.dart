part of '../steps.dart';

/// Analyzes the compiled queries found in a Dart file.
class AnalyzeDartStep extends Step {
  AnalyzeDartStep(Task task, FoundFile file) : super(task, file);

  @override
  final bool isParsing = false;

  void analyze() {
    final parseResult = file.currentResult as ParsedDartFile;

    for (var accessor in parseResult.dbAccessors) {
      final transitivelyAvailable = accessor.resolvedImports
          .where((file) => file.type == FileType.moor)
          .map((file) => file.currentResult as ParsedMoorFile)
          .expand((file) => file.declaredTables);
      final availableTables =
          accessor.tables.followedBy(transitivelyAvailable).toList();
      accessor.allTables = availableTables;

      final parser = SqlParser(this, availableTables, accessor.queries);
      parser.parse();

      accessor.resolvedQueries = parser.foundQueries;
    }
  }
}
