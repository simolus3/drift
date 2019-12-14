import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/builder.dart'; // ignore: implementation_imports
import 'package:analyzer/src/context/context_root.dart'; // ignore: implementation_imports
import 'package:analyzer_plugin/plugin/assist_mixin.dart';
import 'package:analyzer_plugin/plugin/completion_mixin.dart';
import 'package:analyzer_plugin/plugin/folding_mixin.dart';
import 'package:analyzer_plugin/plugin/highlights_mixin.dart';
import 'package:analyzer_plugin/plugin/navigation_mixin.dart';
import 'package:analyzer_plugin/plugin/outline_mixin.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/completion/completion_core.dart';
import 'package:analyzer_plugin/utilities/folding/folding.dart';
import 'package:analyzer_plugin/utilities/highlights/highlights.dart';
import 'package:analyzer_plugin/utilities/navigation/navigation.dart';
import 'package:analyzer_plugin/utilities/outline/outline.dart';
import 'package:moor_generator/src/analyzer/runner/file_graph.dart';
import 'package:moor_generator/src/backends/common/driver.dart';
import 'package:moor_generator/src/backends/common/file_tracker.dart';
import 'package:moor_generator/src/backends/plugin/services/assists/assist_service.dart';
import 'package:moor_generator/src/backends/plugin/services/autocomplete.dart';
import 'package:moor_generator/src/backends/plugin/services/errors.dart';
import 'package:moor_generator/src/backends/plugin/services/folding.dart';
import 'package:moor_generator/src/backends/plugin/services/highlights.dart';
import 'package:moor_generator/src/backends/plugin/services/navigation.dart';
import 'package:moor_generator/src/backends/plugin/services/outline.dart';
import 'package:moor_generator/src/backends/plugin/services/requests.dart';

import 'backend/logger.dart';

class MoorPlugin extends ServerPlugin
    with
        OutlineMixin,
        HighlightsMixin,
        FoldingMixin,
        CompletionMixin,
        AssistsMixin,
        NavigationMixin {
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
      ..exceptions.listen((_) {}); // Consume the stream, otherwise we leak.

    final tracker = FileTracker();
    final errorService = ErrorService(this);

    final driver = MoorDriver(tracker, analysisDriverScheduler, dartDriver,
        fileContentOverlay, resourceProvider);

    driver.completedFiles().where((file) => file.isParsed).listen((file) {
      sendNotificationsForFile(file.uri.path);
      errorService.handleResult(file);
    });

    return driver;
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

  Future<FoundFile> _waitParsed(String path) async {
    final driver = _moorDriverForPath(path);
    if (driver == null) {
      throw RequestFailure(plugin.RequestError(
          plugin.RequestErrorCode.INVALID_PARAMETER,
          "Path isn't covered by plugin: $path"));
    }

    final file = await driver.waitFileParsed(path);
    if (file == null) {
      throw RequestFailure(plugin.RequestError(
          plugin.RequestErrorCode.PLUGIN_ERROR,
          'Unknown file: Neither Dart or moor: $path'));
    }

    return file;
  }

  Future<MoorRequest> _createMoorRequest(String path) async {
    final file = await _waitParsed(path);
    return MoorRequest(file, resourceProvider);
  }

  @override
  List<OutlineContributor> getOutlineContributors(String path) {
    return const [MoorOutlineContributor()];
  }

  @override
  Future<OutlineRequest> getOutlineRequest(String path) {
    return _createMoorRequest(path);
  }

  @override
  List<HighlightsContributor> getHighlightsContributors(String path) {
    return const [MoorHighlightContributor()];
  }

  @override
  Future<HighlightsRequest> getHighlightsRequest(String path) {
    return _createMoorRequest(path);
  }

  @override
  List<FoldingContributor> getFoldingContributors(String path) {
    return const [MoorFoldingContributor()];
  }

  @override
  Future<FoldingRequest> getFoldingRequest(String path) {
    return _createMoorRequest(path);
  }

  @override
  List<CompletionContributor> getCompletionContributors(String path) {
    return const [MoorCompletingContributor()];
  }

  @override
  Future<CompletionRequest> getCompletionRequest(
      plugin.CompletionGetSuggestionsParams parameters) async {
    final path = parameters.file;
    final file = await _waitParsed(path);

    return MoorCompletionRequest(parameters.offset, resourceProvider, file);
  }

  @override
  List<AssistContributor> getAssistContributors(String path) {
    return const [AssistService()];
  }

  @override
  Future<AssistRequest> getAssistRequest(
      plugin.EditGetAssistsParams parameters) async {
    final path = parameters.file;
    final file = await _waitParsed(path);

    return MoorRequestAtPosition(
        file, parameters.length, parameters.offset, resourceProvider);
  }

  @override
  List<NavigationContributor> getNavigationContributors(String path) {
    return const [MoorNavigationContributor()];
  }

  @override
  Future<NavigationRequest> getNavigationRequest(
      plugin.AnalysisGetNavigationParams parameters) async {
    final path = parameters.file;
    final file = await _waitParsed(path);

    return MoorRequestAtPosition(
        file, parameters.length, parameters.offset, resourceProvider);
  }
}
