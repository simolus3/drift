part of '../steps.dart';

class AnalyzeMoorStep extends AnalyzingStep {
  AnalyzeMoorStep(Task task, FoundFile file) : super(task, file);

  Future<void> analyze() async {
    if (file.currentResult == null) {
      // Error during parsing, ignore.
      return;
    }

    final parseResult = file.currentResult as ParsedMoorFile;

    final transitiveImports =
        task.crawlImports(parseResult.resolvedImports!.values).toList();

    // Check that all imports are valid
    parseResult.resolvedImports!.forEach((node, fileRef) {
      if (fileRef.type == FileType.other) {
        reportError(ErrorInMoorFile(
          span: node.span!,
          message: "Invalid import (the file exists, but couldn't be parsed). "
              'Is it a part file?',
        ));
      }
    });

    final availableTables = _availableTables(transitiveImports)
        .followedBy(parseResult.declaredTables)
        .toList();

    final importedViews = _availableViews(transitiveImports).toList();

    EntityHandler(this, parseResult, availableTables).handle();

    await ViewAnalyzer(
            this, availableTables, importedViews, parseResult.imports)
        .resolve(parseResult.declaredViews);

    final availableViews =
        importedViews.followedBy(parseResult.declaredViews).toList();
    final parser =
        SqlAnalyzer(this, availableTables, availableViews, parseResult.queries)
          ..parse();

    parseResult.resolvedQueries = parser.foundQueries;
  }
}
