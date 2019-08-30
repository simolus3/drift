import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:moor_generator/src/analyzer/errors.dart';
import 'package:moor_generator/src/analyzer/results.dart';
import 'package:moor_generator/src/backends/backend.dart';

/// Will store cached data about files that have already been analyzed.
class MoorSession {
  MoorSession();

  Future<DartTask> startDartTask(BackendTask backendTask) async {
    final library = await backendTask.resolveDart(backendTask.entrypoint);
    return DartTask(this, backendTask, library);
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
}

/// Session used to parse a Dart file and extract table information.
class DartTask extends FileTask<ParsedDartFile> {
  final LibraryElement library;

  DartTask(MoorSession session, BackendTask task, this.library)
      : super(task, session);

  @override
  FutureOr<ParsedDartFile> compute() {
    // TODO: implement compute
    return null;
  }
}

class MoorTask extends FileTask<ParsedMoorFile> {
  final List<String> content;

  MoorTask(BackendTask task, MoorSession session, this.content)
      : super(task, session);

  @override
  FutureOr<ParsedMoorFile> compute() {
    // TODO: implement compute
    return null;
  }
}
