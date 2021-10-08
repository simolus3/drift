part of 'parser.dart';

class UseMoorParser {
  final ParseDartStep step;

  UseMoorParser(this.step);

  /// If [element] has a `@UseMoor` annotation, parses the database model
  /// declared by that class and the referenced tables.
  Future<Database> parseDatabase(
      ClassElement element, ConstantReader annotation) async {
    // the types declared in UseMoor.tables
    final tablesOrNull = annotation
        .peek('tables')
        ?.listValue
        .map((obj) => obj.toTypeValue())
        .whereType<DartType>();
    if (tablesOrNull == null) {
      step.reportError(ErrorInDartCode(
        message: 'Could not read tables from @UseMoor annotation! \n'
            'Please make sure that all table classes exist.',
        affectedElement: element,
      ));
    }

    final tableTypes = tablesOrNull ?? [];
    final queryStrings = annotation.peek('queries')?.mapValue ?? {};
    final includes = annotation
            .read('include')
            .objectValue
            .toSetValue()
            ?.map((e) => e.toStringValue()!)
            .toList() ??
        [];

    final parsedTables = await step.parseTables(tableTypes, element);

    final parsedQueries = step.readDeclaredQueries(queryStrings.cast());
    final daoTypes = _readDaoTypes(annotation);

    return Database(
      declaration: DatabaseOrDaoDeclaration(element, step.file),
      declaredTables: parsedTables,
      daos: daoTypes,
      declaredIncludes: includes,
      declaredQueries: parsedQueries,
    );
  }

  List<DartType> _readDaoTypes(ConstantReader annotation) {
    return annotation
            .peek('daos')
            ?.listValue
            .map((obj) => obj.toTypeValue()!)
            .toList() ??
        [];
  }
}
