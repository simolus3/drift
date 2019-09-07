import 'package:analyzer/context/context_root.dart';
// ignore: implementation_imports
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:moor_generator/src/backends/plugin/backend/file_tracker.dart';

import 'backend/driver.dart';
import 'backend/logger.dart';

class MoorPlugin extends ServerPlugin {
  MoorPlugin(ResourceProvider provider) : super(provider) {
    setupLogger(this);
  }

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
  MoorDriver createAnalysisDriver(plugin.ContextRoot contextRoot) {
    // create an analysis driver we can use to resolve Dart files
    final analyzerRoot = ContextRoot(contextRoot.root, contextRoot.exclude,
        pathContext: resourceProvider.pathContext)
      ..optionsFilePath = contextRoot.optionsFile;

    final builder = ContextBuilder(resourceProvider, sdkManager, null)
      ..analysisDriverScheduler = analysisDriverScheduler
      ..byteStore = byteStore
      ..performanceLog = performanceLog
      ..fileContentOverlay = fileContentOverlay;

    // todo we listen because we copied this from the angular plugin. figure out
    // why exactly this is necessary
    final dartDriver = builder.buildDriver(analyzerRoot)
      ..results.listen((_) {}) // Consume the stream, otherwise we leak.
      ..exceptions.listen((_) {}); // Consume the stream, otherwise we leak.;

    final tracker = FileTracker();
    return MoorDriver(tracker, analysisDriverScheduler, dartDriver,
        fileContentOverlay, resourceProvider);
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
}
