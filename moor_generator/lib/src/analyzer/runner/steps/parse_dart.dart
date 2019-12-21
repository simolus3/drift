part of '../steps.dart';

/// Extracts the following information from a Dart file:
/// - [MoorTable]s, which are read from Dart classes extending `Table`.
/// - [Database]s, which are read from `@UseMoor`-annotated classes
/// - [Dao]s, which are read from `@UseDao`-annotated classes.
///
/// Notably, this step does not analyze defined queries.
class ParseDartStep extends Step {
  static const _tableTypeChecker = TypeChecker.fromRuntime(Table);
  static const _generatedInfoChecker = TypeChecker.fromRuntime(TableInfo);
  static const _useMoorChecker = TypeChecker.fromRuntime(UseMoor);
  static const _useDaoChecker = TypeChecker.fromRuntime(UseDao);

  final LibraryElement library;

  MoorDartParser _parser;
  MoorDartParser get parser => _parser;

  final Map<ClassElement, MoorTable> _tables = {};

  ParseDartStep(Task task, FoundFile file, this.library) : super(task, file) {
    _parser = MoorDartParser(this);
  }

  Future<ParsedDartFile> parse() async {
    final reader = LibraryReader(library);
    final databases = <Database>[];
    final daos = <Dao>[];

    for (final declaredClass in reader.classes) {
      if (_isDslTable(declaredClass)) {
        await _parseTable(declaredClass);
      } else {
        for (final annotation in _useMoorChecker.annotationsOf(declaredClass)) {
          final reader = ConstantReader(annotation);
          final database = await parseDatabase(declaredClass, reader);
          if (database != null) databases.add(database);
        }

        for (final annotation in _useDaoChecker.annotationsOf(declaredClass)) {
          final reader = ConstantReader(annotation);
          final dao = await parseDao(declaredClass, reader);
          if (dao != null) daos.add(dao);
        }
      }
    }

    return ParsedDartFile(
      library: library,
      declaredTables: _tables.values.toList(),
      declaredDaos: daos,
      declaredDatabases: databases,
    );
  }

  Future<MoorTable> _parseTable(ClassElement element) async {
    if (!_tables.containsKey(element)) {
      _tables[element] = await parser.parseTable(element);
    }
    return _tables[element];
  }

  /// Parses a [Database] from the [ClassElement] which was annotated
  /// with `@UseMoor` and the [annotation] reader that reads the `@UseMoor`
  /// annotation.
  Future<Database> parseDatabase(
      ClassElement element, ConstantReader annotation) {
    return UseMoorParser(this).parseDatabase(element, annotation);
  }

  /// Parses a [Dao] from a class declaration that has a `UseDao`
  /// [annotation].
  Future<Dao> parseDao(ClassElement element, ConstantReader annotation) {
    return UseDaoParser(this).parseDao(element, annotation);
  }

  /// Resolves a [MoorTable] for the class of each [DartType] in [types].
  /// The [initializedBy] element should be the piece of code that caused the
  /// parsing (e.g. the database class that is annotated with `@UseMoor`). This
  /// will allow for more descriptive error messages.
  Future<List<MoorTable>> parseTables(
      Iterable<DartType> types, Element initializedBy) {
    return Future.wait(types.map((type) {
      if (!_tableTypeChecker.isAssignableFrom(type.element)) {
        reportError(ErrorInDartCode(
          severity: Severity.criticalError,
          message: 'The type $type is not a moor table',
          affectedElement: initializedBy,
        ));
        return Future.value(null);
      } else {
        return _parseTable(type.element as ClassElement);
      }
    })).then((list) {
      // only keep tables that were resolved successfully
      return List.from(list.where((t) => t != null));
    });
  }

  List<DeclaredQuery> readDeclaredQueries(Map<DartObject, DartObject> obj) {
    return obj.entries.map((entry) {
      final key = entry.key.toStringValue();
      final value = entry.value.toStringValue();

      return DeclaredDartQuery(key, value);
    }).toList();
  }

  bool _isDslTable(ClassElement element) {
    // check if the table inherits from the moor table class. The !isExactly
    // check is here because we run this generator on moor itself and we get
    // weird errors for the Table class itself. In weird cases where we iterate
    // over generated code (standalone tool), don't report existing
    // implementations as tables.
    return _tableTypeChecker.isAssignableFrom(element) &&
        !_tableTypeChecker.isExactly(element) &&
        !_generatedInfoChecker.isAssignableFrom(element);
  }
}
