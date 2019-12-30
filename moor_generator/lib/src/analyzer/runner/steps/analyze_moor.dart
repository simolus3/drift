part of '../steps.dart';

class AnalyzeMoorStep extends AnalyzingStep {
  AnalyzeMoorStep(Task task, FoundFile file) : super(task, file);

  void analyze() {
    final parseResult = file.currentResult as ParsedMoorFile;

    final transitiveImports =
        task.crawlImports(parseResult.resolvedImports.values).toList();

    final availableTables = _availableTables(transitiveImports)
        .followedBy(parseResult.declaredTables)
        .toList();

    final parser = SqlParser(this, availableTables, parseResult.queries)
      ..parse();

    EntityHandler(this, parseResult, availableTables).handle();

    parseResult.resolvedQueries = parser.foundQueries;
  }
}
