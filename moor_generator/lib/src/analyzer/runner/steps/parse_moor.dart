part of '../steps.dart';

class ParseMoorStep extends Step {
  final String content;
  final TypeMapper mapper = TypeMapper();
  /* late final */ InlineDartResolver inlineDartResolver;

  ParseMoorStep(Task task, FoundFile file, this.content) : super(task, file) {
    inlineDartResolver = InlineDartResolver(this);
  }

  Future<ParsedMoorFile> parseFile() {
    final parser = MoorParser(this);
    return parser.parseAndAnalyze();
  }
}
