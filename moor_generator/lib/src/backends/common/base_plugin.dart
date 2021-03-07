import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/builder.dart'; // ignore: implementation_imports
import 'package:analyzer/src/context/context_root.dart'; // ignore: implementation_imports
// ignore: implementation_imports
import 'package:analyzer/src/dart/analysis/driver.dart'
    show AnalysisDriverScheduler;
import 'package:analyzer_plugin_fork/plugin/plugin.dart';
import 'package:analyzer_plugin_fork/protocol/protocol_generated.dart' as proto;
import 'package:meta/meta.dart';
import 'package:moor_generator/src/analyzer/options.dart';

import 'driver.dart';
import 'file_tracker.dart';

abstract class BaseMoorPlugin extends ServerPlugin {
  BaseMoorPlugin(ResourceProvider provider) : super(provider);

  /// The [AnalysisDriverScheduler] used to analyze Dart files.
  ///
  /// We don't use a the single [analysisDriverScheduler] from the plugin
  /// because it causes deadlocks when the [MoorDriver] wants to analyze Dart
  /// files.
  AnalysisDriverScheduler get dartScheduler {
    if (_dartScheduler == null) {
      _dartScheduler = AnalysisDriverScheduler(performanceLog);
      _dartScheduler.start();
    }
    return _dartScheduler;
  }

  AnalysisDriverScheduler _dartScheduler;

  @override
  List<String> get fileGlobsToAnalyze => const ['*.moor'];
  @override
  String get name => 'Moor plugin';
  @override
  // docs say that this should a version of _this_ plugin, but they lie. this
  // version will be used to determine compatibility with the analyzer
  String get version => '2.0.0-alpha.0';
  @override
  String get contactInfo =>
      'Create an issue at https://github.com/simolus3/moor/';

  @override
  MoorDriver createAnalysisDriver(proto.ContextRoot contextRoot,
      {MoorOptions options}) {
    // create an analysis driver we can use to resolve Dart files
    final analyzerRoot = ContextRoot(
      contextRoot.root,
      contextRoot.exclude,
      pathContext: resourceProvider.pathContext,
    )..optionsFilePath = contextRoot.optionsFile;

    final builder = ContextBuilder(resourceProvider, sdkManager, null)
      ..analysisDriverScheduler = dartScheduler
      ..byteStore = byteStore
      ..performanceLog = performanceLog;
    final workspace = ContextBuilder.createWorkspace(
      resourceProvider: resourceProvider,
      options: builder.builderOptions,
      rootPath: contextRoot.root,
    );
    // todo we listen because we copied this from the angular plugin. figure out
    // why exactly this is necessary
    final dartDriver = builder.buildDriver(analyzerRoot, workspace)
      ..results.listen((_) {}) // Consume the stream, otherwise we leak.
      ..exceptions.listen((_) {}); // Consume the stream, otherwise we leak.

    final tracker = FileTracker();
    final driver = MoorDriver(tracker, analysisDriverScheduler, dartDriver,
        resourceProvider, options, contextRoot.root);
    didCreateDriver(driver);

    return driver;
  }

  @visibleForOverriding
  void didCreateDriver(MoorDriver driver) {}

  @override
  MoorDriver driverForPath(String path) {
    final driver = super.driverForPath(path);
    if (driver is MoorDriver) {
      return driver;
    }
    return null;
  }

  @override
  Future<proto.PluginShutdownResult> handlePluginShutdown(
      proto.PluginShutdownParams parameters) async {
    for (final driver in driverMap.values) {
      driver.dispose();
    }

    return proto.PluginShutdownResult();
  }
}
