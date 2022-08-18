import 'package:build/build.dart';
import 'package:drift_dev/moor_generator.dart';
import 'package:drift_dev/src/analyzer/errors.dart';
import 'package:drift_dev/src/analyzer/options.dart';
import 'package:drift_dev/src/analyzer/runner/file_graph.dart';
import 'package:drift_dev/src/analyzer/runner/task.dart';
import 'package:drift_dev/src/analyzer/session.dart';
import 'package:test/test.dart';

import '../utils/test_backend.dart';

class TestState {
  TestBackend backend;
  MoorSession session;

  TestState(this.backend, this.session);

  factory TestState.withContent(Map<String, String> content,
      {DriftOptions? options}) {
    final backend = TestBackend(
      {
        for (final entry in content.entries)
          AssetId.parse(entry.key): entry.value,
      },
    );
    final session = MoorSession(backend);
    if (options != null) {
      session.options = options;
    }
    return TestState(backend, session);
  }

  Future<Task> runTask(String entrypointUri) async {
    final backendTask = backend.startTask(Uri.parse(entrypointUri));
    final task = session.startTask(backendTask);
    await task.runTask();
    return task;
  }

  FoundFile file(String uri) {
    return session.registerFile(Uri.parse(uri));
  }

  Future<FoundFile> analyze(String uri) async {
    await runTask(uri);
    return file(uri);
  }

  void close() {
    backend.finish();
  }
}

// Matchers
Matcher returnsColumns(Map<String, DriftSqlType> columns) {
  return _HasInferredColumnTypes(columns);
}

class _HasInferredColumnTypes extends CustomMatcher {
  _HasInferredColumnTypes(dynamic expected)
      : super('Select query with inferred columns', 'columns', expected);

  @override
  Object? featureValueOf(dynamic actual) {
    if (actual is! SqlSelectQuery) {
      return actual;
    }

    final resultSet = actual.resultSet;
    return {for (final column in resultSet.columns) column.name: column.type};
  }
}

extension ExpectErrors on FoundFile {
  void expectDartError(dynamic matcher, String lexeme) {
    expect(
        errors.errors,
        contains(isA<ErrorInDartCode>()
            .having((e) => e.message, 'message', matcher)
            .having((e) => e.span?.text, 'span.text', lexeme)));
  }
}
