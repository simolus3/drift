part of 'parser.dart';

class UseDaoParser {
  final ParseDartStep step;

  UseDaoParser(this.step);

  /// If [element] has a `@UseDao` annotation, parses the database model
  /// declared by that class and the referenced tables.
  Future<Dao?> parseDao(ClassElement element, ConstantReader annotation) async {
    final dbType = element.allSupertypes
        .firstWhereOrNull((i) => i.element2.name == 'DatabaseAccessor');

    if (dbType == null) {
      step.reportError(ErrorInDartCode(
        affectedElement: element,
        severity: Severity.criticalError,
        message: 'This class must inherit from DatabaseAccessor',
      ));
      return null;
    }

    // inherits from DatabaseAccessor<T>, we want to know which T
    final dbImpl = dbType.typeArguments.single;
    if (dbImpl.isDynamic) {
      step.reportError(ErrorInDartCode(
        affectedElement: element,
        severity: Severity.criticalError,
        message: 'This class must inherit from DatabaseAccessor<T>, where T '
            'is an actual type of a database.',
      ));
      return null;
    }

    final tableTypes = annotation
            .peek('tables')
            ?.listValue
            .map((obj) => obj.toTypeValue())
            .whereType<DartType>() ??
        const [];
    final queryStrings = annotation.peek('queries')?.mapValue ?? {};

    final viewTypes = annotation
            .peek('views')
            ?.listValue
            .map((obj) => obj.toTypeValue())
            .whereType<DartType>() ??
        const [];

    final includes = annotation
            .read('include')
            .objectValue
            .toSetValue()
            ?.map((e) => e.toStringValue())
            .whereType<String>()
            .toList() ??
        [];

    final parsedTables = await step.parseTables(tableTypes, element);
    final parsedViews = await step.parseViews(viewTypes, element, parsedTables);
    final parsedQueries = step.readDeclaredQueries(queryStrings.cast());

    return Dao(
      declaration: DatabaseOrDaoDeclaration(element, step.file),
      dbClass: dbImpl,
      declaredTables: parsedTables,
      declaredViews: parsedViews,
      declaredIncludes: includes,
      declaredQueries: parsedQueries,
    );
  }
}
