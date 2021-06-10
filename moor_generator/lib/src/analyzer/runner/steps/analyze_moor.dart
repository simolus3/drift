//@dart=2.9
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
        task.crawlImports(parseResult.resolvedImports.values).toList();

    // Check that all imports are valid
    parseResult.resolvedImports.forEach((node, fileRef) {
      if (fileRef.type == FileType.other) {
        reportError(ErrorInMoorFile(
          span: node.span,
          message: "Invalid import (the file exists, but couldn't be parsed). "
              'Is it a part file?',
        ));
      }
    });

    final availableTables = _availableTables(transitiveImports)
        .followedBy(parseResult.declaredTables)
        .toList();

    final availableViews = _availableViews(transitiveImports)
        .followedBy(parseResult.declaredViews)
        .toList();

    EntityHandler(this, parseResult, availableTables).handle();

    await ViewAnalyzer(
            this, availableTables, availableViews, parseResult.imports)
        .resolve();

    final parser =
        SqlAnalyzer(this, availableTables, availableViews, parseResult.queries)
          ..parse();

    parseResult.resolvedQueries = parser.foundQueries;
  }
}
