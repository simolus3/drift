//@dart=2.9
part of 'parser.dart';

class UseMoorParser {
  final ParseDartStep step;

  UseMoorParser(this.step);

  /// If [element] has a `@UseMoor` annotation, parses the database model
  /// declared by that class and the referenced tables.
  Future<Database> parseDatabase(
      ClassElement element, ConstantReader annotation) async {
    // the types declared in UseMoor.tables
    final tablesOrNull =
        annotation.peek('tables')?.listValue?.map((obj) => obj.toTypeValue());
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
            ?.map((e) => e.toStringValue())
            ?.toList() ??
        [];

    final parsedTables = await step.parseTables(tableTypes, element);

    final parsedQueries = step.readDeclaredQueries(queryStrings);
    final daoTypes = _readDaoTypes(annotation);

    _parseForeignKeys(parsedTables);
    _parseConverters(parsedTables, annotation);

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
            ?.map((obj) => obj.toTypeValue())
            ?.toList() ??
        [];
  }

  void _parseForeignKeys(List<MoorTable> parsedTables) {
    for (final table in parsedTables) {
      final fkColumns =
          table.columns.where((element) => element.isForeignKey).toList();
      for (final c in fkColumns) {
        final rt = parsedTables.firstWhere(
            (t) => t.fromClass == c.fkReferences.element,
            orElse: () => null);
        if (rt != null) {
          var delete = '';
          var update = '';

          if (c.fkOnDelete != null) {
            update = ' ON DELETE ${c.fkOnDelete}';
          }

          if (c.fkOnUpdate != null) {
            update = ' ON UPDATE ${c.fkOnUpdate}';
          }

          table.overrideTableConstraints.add('FOREIGN KEY (${c.name.name}) '
              'REFERENCES ${rt.sqlName}(${c.fkColumn})$delete$update');
        }
      }
    }
  }

  void _parseConverters(
      List<MoorTable> parsedTables, ConstantReader annotation) {
    final converterList = annotation.peek('converters')?.mapValue ?? {};
    final converters = converterList
        .map((key, value) => MapEntry(key.toTypeValue(), '${value.type}()'));

    final foreignKeyConverter = annotation
        .peek('foreignKeyConverter')
        ?.objectValue
        ?.type
        ?.element
        ?.name;

    final nullableForeignKeyConverter = annotation
        .peek('nullableForeignKeyConverter')
        ?.objectValue
        ?.type
        ?.element
        ?.name;

    for (final table in parsedTables) {
      var startIndex = table.converters.length;
      for (final c in table.columns) {
        if (c.typeConverter == null) {
          final columnDeclaration = c.declaration as DartColumnDeclaration;
          if (columnDeclaration.element is FieldElement) {
            final fieldElement = columnDeclaration.element as FieldElement;
            final type = fieldElement.type;

            String converter;
            if (c.isForeignKey && !c.nullable && foreignKeyConverter != null) {
              converter = '$foreignKeyConverter<$type>()';
            } else if (c.isForeignKey &&
                c.nullable &&
                nullableForeignKeyConverter != null) {
              converter = '$nullableForeignKeyConverter<$type>()';
            } else {
              final convType = converters.keys.firstWhere(
                  (element) => _typeEquals(
                      type as InterfaceType, element as InterfaceType),
                  orElse: () => null);
              converter = converters[convType];
            }

            if (converter != null) {
              c.typeConverter = UsedTypeConverter(
                  expression: converter, mappedType: type, sqlType: c.type);
              c.typeConverter.index = startIndex++;
              c.typeConverter.table = table;
            }
          }
        }
      }
    }
  }

  bool _equalArrays(List<DartType> first, List<DartType> second) {
    if (first.length != second.length) {
      return false;
    }
    for (var i = 0; i < first.length; i++) {
      if (first[i] != second[i]) {
        return false;
      }
    }
    return true;
  }

  bool _typeEquals(InterfaceType type1, InterfaceType type2) {
    return type1.element == type2.element &&
        _equalArrays(type1.typeArguments, type2.typeArguments);
  }
}
