part of 'parser.dart';

class UseDaoParser {
  final DartTask dartTask;

  UseDaoParser(this.dartTask);

  /// If [element] has a `@UseDao` annotation, parses the database model
  /// declared by that class and the referenced tables.
  Future<SpecifiedDao> parseDao(
      ClassElement element, ConstantReader annotation) async {
    final tableTypes =
        annotation.peek('tables')?.listValue?.map((obj) => obj.toTypeValue()) ??
            [];
    final queryStrings = annotation.peek('queries')?.mapValue ?? {};

    final includes = annotation
            .read('include')
            .objectValue
            .toSetValue()
            ?.map((e) => e.toStringValue()) ??
        {};

    final parsedTables = await dartTask.parseTables(tableTypes, element);
    parsedTables.addAll(await dartTask.resolveIncludes(includes));

    final parsedQueries =
        await dartTask.parseQueries(queryStrings, parsedTables);

    return SpecifiedDao(element, parsedTables, parsedQueries);
  }
}
