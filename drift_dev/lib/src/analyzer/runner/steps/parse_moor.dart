part of '../steps.dart';

class ParseMoorStep extends Step {
  final String content;
  final TypeMapper mapper = TypeMapper();

  ParseMoorStep(Task task, FoundFile file, this.content) : super(task, file);

  Future<ParsedMoorFile> parseFile() {
    final parser = MoorParser(this);
    return parser.parseAndAnalyze();
  }
}
