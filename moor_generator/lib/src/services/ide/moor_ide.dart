import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:moor_generator/src/analyzer/session.dart';

import 'package:path/path.dart';

import 'highlights.dart';

/// Provides IDE services for moor projects.
class MoorIde {
  final MoorSession session;
  final IdeFileManagement files;

  MoorIde(this.session, [this.files = const _DefaultManagement()]);

  Future<List<HighlightRegion>> highlight(String path) async {
    await files.waitUntilParsed(path);

    final uri = files.fsPathToUri(path);
    final highlighter = MoorHighlightComputer(session.registerFile(uri));
    return highlighter.computeHighlights();
  }
}

abstract class IdeFileManagement {
  Uri fsPathToUri(String path);

  Future<void> waitUntilParsed(String path);
}

class _DefaultManagement implements IdeFileManagement {
  const _DefaultManagement();

  @override
  Uri fsPathToUri(String path) => toUri(path);

  @override
  Future<void> waitUntilParsed(String path) async {}
}
