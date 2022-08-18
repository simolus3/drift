part of '../steps.dart';

class ParseMoorStep extends Step {
  final String content;
  final TypeMapper mapper;

  ParseMoorStep(Task task, FoundFile file, this.content)
      : mapper = TypeMapper(options: task.session.options),
        super(task, file);

  Future<ParsedDriftFile> parseFile() async {
    final parser = MoorParser(this, await task.helper);
    return parser.parseAndAnalyze();
  }
}
