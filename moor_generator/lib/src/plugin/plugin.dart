import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/plugin/highlights_mixin.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/utilities/highlights/highlights.dart';
import 'package:moor_generator/src/plugin/state/file_tracker.dart';

import 'analyzer/highlights/request.dart';
import 'analyzer/highlights/sql_highlighter.dart';
import 'analyzer/moor_analyzer.dart';
import 'driver.dart';

class MoorPlugin extends ServerPlugin with HighlightsMixin {
  MoorPlugin(ResourceProvider provider) : super(provider);

  @override
  final List<String> fileGlobsToAnalyze = const ['*.moor'];
  @override
  final String name = 'Moor plugin';
  @override
  // docs say that this should a version of _this_ plugin, but they lie. this
  // version will be used to determine compatibility with the analyzer
  final String version = '2.0.0-alpha.0';
  @override
  final String contactInfo =
      'Create an issue at https://github.com/simolus3/moor/';

  @override
  MoorDriver createAnalysisDriver(ContextRoot contextRoot) {
    final tracker = FileTracker();
    final analyzer = MoorAnalyzer();
    return MoorDriver(
        tracker, analysisDriverScheduler, analyzer, resourceProvider);
  }

  @override
  void contentChanged(String path) {
    _moorDriverForPath(path)?.handleFileChanged(path);
  }

  MoorDriver _moorDriverForPath(String path) {
    final driver = super.driverForPath(path);

    if (driver is! MoorDriver) return null;
    return driver as MoorDriver;
  }

  @override
  List<HighlightsContributor> getHighlightsContributors(String path) {
    return const [SqlHighlighter()];
  }

  @override
  Future<HighlightsRequest> getHighlightsRequest(String path) async {
    final driver = _moorDriverForPath(path);
    if (driver == null) {
      throw RequestFailure(
          RequestErrorFactory.pluginError('Not driver set for path', null));
    }

    final parsed = await driver.parseMoorFile(path);

    return MoorHighlightingRequest(parsed, path, resourceProvider);
  }
}
