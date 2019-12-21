import 'package:build/build.dart';
import 'package:moor_generator/src/analyzer/runner/file_graph.dart';
import 'package:moor_generator/src/analyzer/runner/task.dart';
import 'package:moor_generator/src/analyzer/session.dart';

import '../../utils/test_backend.dart';

class TestState {
  TestBackend backend;
  MoorSession session;

  TestState(this.backend, this.session);

  factory TestState.withContent(Map<String, String> content) {
    final backend = TestBackend({
      for (final entry in content.entries)
        AssetId.parse(entry.key): entry.value,
    });
    final session = MoorSession(backend);
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
}
