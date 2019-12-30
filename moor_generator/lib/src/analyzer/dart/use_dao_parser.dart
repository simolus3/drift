part of 'parser.dart';

class UseDaoParser {
  final ParseDartStep step;

  UseDaoParser(this.step);

  /// If [element] has a `@UseDao` annotation, parses the database model
  /// declared by that class and the referenced tables.
  Future<Dao> parseDao(ClassElement element, ConstantReader annotation) async {
    final dbType = element.allSupertypes
        .firstWhere((i) => i.name == 'DatabaseAccessor', orElse: () => null);

    if (dbType == null) {
      step.reportError(ErrorInDartCode(
        affectedElement: element,
        severity: Severity.criticalError,
        message: 'This class must directly inherit from DatabaseAccessor',
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

    final tableTypes =
        annotation.peek('tables')?.listValue?.map((obj) => obj.toTypeValue()) ??
            [];
    final queryStrings = annotation.peek('queries')?.mapValue ?? {};

    final includes = annotation
            .read('include')
            .objectValue
            .toSetValue()
            ?.map((e) => e.toStringValue())
            ?.toList() ??
        [];

    final parsedTables = await step.parseTables(tableTypes, element);
    final parsedQueries = step.readDeclaredQueries(queryStrings);

    return Dao(
      declaration: DatabaseOrDaoDeclaration(element, step.file),
      dbClass: dbImpl,
      declaredTables: parsedTables,
      declaredIncludes: includes,
      declaredQueries: parsedQueries,
    );
  }
}
