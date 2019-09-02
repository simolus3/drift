part of 'parser.dart';

class UseMoorParser {
  final DartTask task;

  UseMoorParser(this.task);

  /// If [element] has a `@UseMoor` annotation, parses the database model
  /// declared by that class and the referenced tables.
  Future<SpecifiedDatabase> parseDatabase(
      ClassElement element, ConstantReader annotation) async {
    // the types declared in UseMoor.tables
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

    final parsedTables = await task.parseTables(tableTypes, element);
    parsedTables.addAll(await task.resolveIncludes(includes));

    final parsedQueries = await task.parseQueries(queryStrings, parsedTables);
    final daoTypes = _readDaoTypes(annotation);

    return SpecifiedDatabase(element, parsedTables, daoTypes, parsedQueries);
  }

  List<DartType> _readDaoTypes(ConstantReader annotation) {
    return annotation
        .peek('daos')
        .listValue
        .map((obj) => obj.toTypeValue())
        .toList();
  }
}
