import 'dart:async';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:moor/moor.dart' show Table;
import 'package:moor_generator/src/analyzer/dart/parser.dart';
import 'package:moor_generator/src/analyzer/errors.dart';
import 'package:moor_generator/src/analyzer/moor/parser.dart';
import 'package:moor_generator/src/analyzer/results.dart';
import 'package:moor_generator/src/analyzer/sql_queries/sql_parser.dart';
import 'package:moor_generator/src/analyzer/sql_queries/type_mapping.dart';
import 'package:moor_generator/src/backends/backend.dart';
import 'package:moor_generator/src/model/specified_dao.dart';
import 'package:moor_generator/src/model/specified_database.dart';
import 'package:moor_generator/src/model/specified_table.dart';
import 'package:moor_generator/src/model/sql_query.dart';
import 'package:source_gen/source_gen.dart';

/// Will store cached data about files that have already been analyzed.
class MoorSession {
  MoorSession();

  Future<DartTask> startDartTask(BackendTask backendTask, {Uri uri}) async {
    final input = uri ?? backendTask.entrypoint;
    final library = await backendTask.resolveDart(input);
    return DartTask(this, backendTask, library);
  }

  Future<MoorTask> startMoorTask(BackendTask backendTask, {Uri uri}) async {
    final input = uri ?? backendTask.entrypoint;
    final source = await backendTask.readMoor(input);
    return MoorTask(backendTask, this, source);
  }
}

/// Used to parse and analyze a single file.
abstract class FileTask<R extends ParsedFile> {
  final BackendTask backendTask;
  final MoorSession session;

  final ErrorSink errors = ErrorSink();

  FileTask(this.backendTask, this.session);

  void reportError(MoorError error) => errors.report(error);

  FutureOr<R> compute();

  void printErrors() {
    final foundErrors = errors.errors;
    if (foundErrors.isNotEmpty) {
      final log = backendTask.log;

      log.warning('There were some errors while running '
          'moor_generator on ${backendTask.entrypoint}:');

      for (var error in foundErrors) {
        final printer = error.isError ? log.warning : log.info;
        error.writeDescription(printer);
      }
    }
  }
}

/// Session used to parse a Dart file and extract table information.
class DartTask extends FileTask<ParsedDartFile> {
  static const tableTypeChecker = const TypeChecker.fromRuntime(Table);

  final LibraryElement library;
  MoorDartParser _parser;
  MoorDartParser get parser => _parser;

  DartTask(MoorSession session, BackendTask task, this.library)
      : super(task, session) {
    _parser = MoorDartParser(this);
  }

  @override
  FutureOr<ParsedDartFile> compute() {
    // TODO: implement compute
    return null;
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
      if (!tableTypeChecker.isAssignableFrom(type.element)) {
        reportError(ErrorInDartCode(
          severity: Severity.criticalError,
          message: 'The type $type is not a moor table',
          affectedElement: initializedBy,
        ));
        return null;
      } else {
        return parser.parseTable(type.element as ClassElement);
      }
    })).then((list) {
      // only keep tables that were resolved successfully
      return List.from(list.where((t) => t != null));
    });
  }

  /// Reads all tables declared in sql by a `.moor` file in [paths].
  Future<List<SpecifiedTable>> resolveIncludes(Iterable<String> paths) {
    return Stream.fromFutures(paths.map(
            (path) => session.startMoorTask(backendTask, uri: Uri.parse(path))))
        .asyncMap((task) async {
          final result = await task.compute();

          // add errors from nested task to this task as well.
          task.errors.errors.forEach(reportError);

          return result;
        })
        .expand((file) => file.declaredTables)
        .toList();
  }

  Future<List<SqlQuery>> parseQueries(
      Map<DartObject, DartObject> fromAnnotation,
      List<SpecifiedTable> availableTables) {
    // no queries declared, so there is no point in starting a sql engine
    if (fromAnnotation.isEmpty) return Future.value([]);

    final parser = SqlParser(this, availableTables, fromAnnotation)..parse();

    return Future.value(parser.foundQueries);
  }
}

class MoorTask extends FileTask<ParsedMoorFile> {
  final String content;
  final TypeMapper mapper = TypeMapper();

  MoorTask(BackendTask task, MoorSession session, this.content)
      : super(task, session);

  @override
  FutureOr<ParsedMoorFile> compute() {
    final parser = MoorParser(this);
    return parser.parseAndAnalyze();
  }
}
