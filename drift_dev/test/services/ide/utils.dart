import 'package:build/build.dart';
import 'package:drift_dev/src/analyzer/session.dart';
import 'package:drift_dev/src/services/ide/moor_ide.dart';

import 'package:path/path.dart';

import '../../utils/test_backend.dart';

MoorIde spawnIde(Map<AssetId, String> content) {
  final backend = TestBackend(content, enableDartAnalyzer: false);
  final session = MoorSession(backend);
  return MoorIde(session, _FileManagementForTesting(session, backend));
}

class _FileManagementForTesting implements IdeFileManagement {
  final TestBackend backend;
  final MoorSession session;

  _FileManagementForTesting(this.session, this.backend);

  @override
  Uri fsPathToUri(String path) {
    final segments = posix.split(path).skip(1);
    final asset = AssetId(segments.first, segments.skip(1).join('/'));
    return asset.uri;
  }

  @override
  Future<void> waitUntilParsed(String path) async {
    final task = session.startTask(backend.startTask(fsPathToUri(path)));
    await task.runTask();
  }
}
