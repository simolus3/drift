import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:moor/moor.dart';
import 'package:moor_generator/src/analyzer/dart/parser.dart';
import 'package:moor_generator/src/analyzer/errors.dart';
import 'package:moor_generator/src/analyzer/runner/file_graph.dart';
import 'package:moor_generator/src/analyzer/runner/results.dart';
import 'package:moor_generator/src/analyzer/moor/inline_dart_resolver.dart';
import 'package:moor_generator/src/analyzer/moor/parser.dart';
import 'package:moor_generator/src/analyzer/sql_queries/sql_parser.dart';
import 'package:moor_generator/src/analyzer/sql_queries/type_mapping.dart';
import 'package:moor_generator/src/analyzer/runner/task.dart';
import 'package:moor_generator/src/model/specified_db_classes.dart';
import 'package:moor_generator/src/model/specified_table.dart';
import 'package:moor_generator/src/model/sql_query.dart';
import 'package:source_gen/source_gen.dart';

/// A [Step] performs actions for a [Task] on a single file.
abstract class Step {
  final Task task;
  final FoundFile file;
  final ErrorSink errors = ErrorSink();

  bool get isParsing => true;

  String get path => file.uri.path;

  Step(this.task, this.file);

  void reportError(MoorError error) =>
      errors.report(error..wasDuringParsing = isParsing);
}

/// Extracts the following information from a Dart file:
/// - [SpecifiedTable]s, which are read from Dart classes extending `Table`.
/// - [SpecifiedDatabase]s, which are read from `@UseMoor`-annotated classes
/// - [SpecifiedDao]s, which are read from `@UseDao`-annotated classes.
///
/// Notably, this step does not analyze defined queries.
class ParseDartStep extends Step {
  static const _tableTypeChecker = const TypeChecker.fromRuntime(Table);
  static const _useMoorChecker = const TypeChecker.fromRuntime(UseMoor);
  static const _useDaoChecker = const TypeChecker.fromRuntime(UseDao);

  final LibraryElement library;

  MoorDartParser _parser;
  MoorDartParser get parser => _parser;

  final Map<ClassElement, SpecifiedTable> _tables = {};

  ParseDartStep(Task task, FoundFile file, this.library) : super(task, file) {
    _parser = MoorDartParser(this);
  }

  Future<ParsedDartFile> parse() async {
    final reader = LibraryReader(library);
    final databases = <SpecifiedDatabase>[];
    final daos = <SpecifiedDao>[];

    for (var declaredClass in reader.classes) {
      if (_tableTypeChecker.isAssignableFrom(declaredClass)) {
        await _parseTable(declaredClass);
      } else {
        for (var annotation in _useMoorChecker.annotationsOf(declaredClass)) {
          final reader = ConstantReader(annotation);
          databases.add(await parseDatabase(declaredClass, reader));
        }

        for (var annotation in _useDaoChecker.annotationsOf(declaredClass)) {
          final reader = ConstantReader(annotation);
          daos.add(await parseDao(declaredClass, reader));
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

  Future<SpecifiedTable> _parseTable(ClassElement element) async {
    if (!_tables.containsKey(element)) {
      _tables[element] = await parser.parseTable(element);
    }
    return _tables[element];
  }

  /// Parses a [SpecifiedDatabase] from the [ClassElement] which was annotated
  /// with `@UseMoor` and the [annotation] reader that reads the `@UseMoor`
  /// annotation.
  Future<SpecifiedDatabase> parseDatabase(
      ClassElement element, ConstantReader annotation) {
    return UseMoorParser(this).parseDatabase(element, annotation);
  }

  /// Parses a [SpecifiedDao] from a class declaration that has a `UseDao`
  /// [annotation].
  Future<SpecifiedDao> parseDao(
      ClassElement element, ConstantReader annotation) {
    return UseDaoParser(this).parseDao(element, annotation);
  }

  /// Resolves a [SpecifiedTable] for the class of each [DartType] in [types].
  /// The [initializedBy] element should be the piece of code that caused the
  /// parsing (e.g. the database class that is annotated with `@UseMoor`). This
  /// will allow for more descriptive error messages.
  Future<List<SpecifiedTable>> parseTables(
      Iterable<DartType> types, Element initializedBy) {
    return Future.wait(types.map((type) {
      if (!_tableTypeChecker.isAssignableFrom(type.element)) {
        reportError(ErrorInDartCode(
          severity: Severity.criticalError,
          message: 'The type $type is not a moor table',
          affectedElement: initializedBy,
        ));
        return null;
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
      final value = entry.key.toStringValue();

      return DeclaredQuery(key, value);
    }).toList();
  }
}

class ParseMoorFile extends Step {
  final String content;
  final TypeMapper mapper = TypeMapper();
  /* late final */ InlineDartResolver inlineDartResolver;

  ParseMoorFile(Task task, FoundFile file, this.content) : super(task, file) {
    inlineDartResolver = InlineDartResolver(this);
  }

  Future<ParsedMoorFile> parseFile() {
    final parser = MoorParser(this);
    return parser.parseAndAnalyze();
  }
}

/// Analyzes the compiled queries found in a Dart file.
class AnalyzeDartStep extends Step {
  AnalyzeDartStep(Task task, FoundFile file) : super(task, file);

  @override
  final bool isParsing = false;

  void analyze() {
    final parseResult = file.currentResult as ParsedDartFile;

    for (var accessor in parseResult.dbAccessors) {
      final transitivelyAvailable = accessor.resolvedImports
          .where((file) => file.type == FileType.moor)
          .map((file) => file.currentResult as ParsedMoorFile)
          .expand((file) => file.declaredTables);
      final availableTables =
          accessor.tables.followedBy(transitivelyAvailable).toList();
      accessor.allTables = availableTables;

      final parser = SqlParser(this, availableTables, accessor.queries);
      parser.parse();

      accessor.resolvedQueries = parser.foundQueries;
    }
  }
}
