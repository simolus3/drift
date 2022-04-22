part of '../steps.dart';

class ParseMoorStep extends Step {
  final String content;
  final TypeMapper mapper = TypeMapper();

  ParseMoorStep(Task task, FoundFile file, this.content) : super(task, file);

  Future<ParsedMoorFile> parseFile() async {
    final parser = MoorParser(this, await task.helper);
    return parser.parseAndAnalyze();
  }
}
