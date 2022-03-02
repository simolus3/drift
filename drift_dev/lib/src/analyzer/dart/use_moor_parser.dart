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
        message: 'Could not read tables from @DriftDatabase annotation! \n'
            'Please make sure that all table classes exist.',
        affectedElement: element,
      ));
    }

    final viewTypes = annotation
            .peek('views')
            ?.listValue
            .map((obj) => obj.toTypeValue())
            .whereType<DartType>() ??
        const [];

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
    final parsedViews = await step.parseViews(viewTypes, element, parsedTables);
    final parsedQueries = step.readDeclaredQueries(queryStrings.cast());
    final daoTypes = _readDaoTypes(annotation);

    return Database(
      declaration: DatabaseOrDaoDeclaration(element, step.file),
      declaredTables: parsedTables,
      declaredViews: parsedViews,
      daos: daoTypes,
      declaredIncludes: includes,
      declaredQueries: parsedQueries,
      schemaVersion: await _readSchemaVersion(element),
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

  Future<int?> _readSchemaVersion(ClassElement dbClass) async {
    final element = dbClass.thisType.getGetter('schemaVersion')?.variable;
    if (element == null) return null;

    final helper = MoorDartParser(step);

    if (element.isSynthetic) {
      // Getter, read from `=>` body if possible.
      final expr = helper.returnExpressionOfMethod(
          await helper.loadElementDeclaration(element.getter!)
              as MethodDeclaration,
          reportErrorOnFailure: false);
      if (expr is IntegerLiteral) {
        return expr.value;
      }
    } else {
      final astField =
          await helper.loadElementDeclaration(element) as VariableDeclaration;
      if (astField.initializer is IntegerLiteral) {
        return (astField.initializer as IntegerLiteral).value;
      }
    }

    return null;
  }
}
