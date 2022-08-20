import 'package:build/build.dart';
import 'package:drift_dev/src/analysis/backend.dart';
import 'package:logging/logging.dart';
import 'package:test/scaffolding.dart';

class TestBackend extends DriftBackend {
  final Map<String, String> sourceContents;

  TestBackend(Map<String, String> sourceContents)
      : sourceContents = {
          for (final entry in sourceContents.entries)
            AssetId.parse(entry.key).uri.toString(): entry.value,
        };

  factory TestBackend.inTest(Map<String, String> sourceContents) {
    final backend = TestBackend(sourceContents);
    addTearDown(backend.dispose);

    return backend;
  }

  @override
  Logger get log => Logger.root;

  @override
  Future<String> readAsString(Uri uri) async {
    return sourceContents[uri.toString()] ??
        (throw StateError('No source for $uri'));
  }

  Future<void> dispose() async {}
}
