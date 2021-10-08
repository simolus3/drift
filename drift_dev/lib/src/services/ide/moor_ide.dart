//@dart=2.9
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:drift_dev/src/analyzer/session.dart';
import 'package:drift_dev/src/services/ide/assists/assist_service.dart';

import 'package:path/path.dart';

import 'highlights.dart';

/// Provides IDE services for moor projects.
class MoorIde {
  final MoorSession session;
  final IdeFileManagement files;

  final AssistContributor _assistContributor = AssistContributor();

  MoorIde(this.session, [this.files = const _DefaultManagement()]);

  Future<List<HighlightRegion>> highlight(String path) async {
    await files.waitUntilParsed(path);

    final uri = files.fsPathToUri(path);
    final highlighter = MoorHighlightComputer(session.registerFile(uri));
    return highlighter.computeHighlights();
  }

  Future<List<PrioritizedSourceChange>> assists(
      String path, int offset, int length) async {
    await files.waitUntilParsed(path);

    final uri = files.fsPathToUri(path);
    return _assistContributor.computeAssists(
        session.registerFile(uri), offset, length, path);
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
