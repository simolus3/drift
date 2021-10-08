//@dart=2.9
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer_plugin/plugin/completion_mixin.dart';
import 'package:analyzer_plugin/plugin/folding_mixin.dart';
import 'package:analyzer_plugin/plugin/navigation_mixin.dart';
import 'package:analyzer_plugin/plugin/outline_mixin.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/utilities/completion/completion_core.dart';
import 'package:analyzer_plugin/utilities/folding/folding.dart';
import 'package:analyzer_plugin/utilities/navigation/navigation.dart';
import 'package:analyzer_plugin/utilities/outline/outline.dart';
import 'package:drift_dev/src/analyzer/runner/file_graph.dart';
import 'package:drift_dev/src/backends/common/driver.dart';
import 'package:drift_dev/src/backends/plugin/services/autocomplete.dart';
import 'package:drift_dev/src/backends/plugin/services/errors.dart';
import 'package:drift_dev/src/backends/plugin/services/folding.dart';
import 'package:drift_dev/src/backends/plugin/services/navigation.dart';
import 'package:drift_dev/src/backends/plugin/services/outline.dart';
import 'package:drift_dev/src/backends/plugin/services/requests.dart';
import 'package:drift_dev/src/services/ide/moor_ide.dart';

import 'logger.dart';

class MoorPlugin extends ServerPlugin
    with OutlineMixin, FoldingMixin, CompletionMixin, NavigationMixin {
  final Map<ContextRoot, MoorDriver> drivers = {};

  ErrorService errorService;

  MoorPlugin(ResourceProvider provider) : super(provider) {
    setupLogger(this);
    errorService = ErrorService(this);
  }

  factory MoorPlugin.forProduction() {
    return MoorPlugin(PhysicalResourceProvider.INSTANCE);
  }

  @override
  List<String> get fileGlobsToAnalyze => const ['*.moor'];
  @override
  String get name => 'Moor plugin';
  @override
  // docs say that this should a version of _this_ plugin, but they lie. this
  // version will be used to determine compatibility with the analyzer
  String get version => '4.4.1';
  @override
  String get contactInfo =>
      'Create an issue at https://github.com/simolus3/moor/';

  void _didCreateDriver(MoorDriver driver) {
    driver.tryToLoadOptions();
    driver.session
        .completedFiles()
        .where((file) => file.isParsed)
        .listen((file) {
      sendNotificationsForFile(file.uri.path);
      errorService.handleResult(file);
    });
  }

  @override
  Null createAnalysisDriver(plugin.ContextRoot contextRoot) {
    throw UnsupportedError('Using custom driver management');
  }

  MoorDriver _moorDriverForPath(String path) {
    for (final driver in drivers.values) {
      if (driver.context.contextRoot.isAnalyzed(path)) return driver;
    }

    return null;
  }

  MoorDriver _moorDriverOrFail(String path) {
    final driver = _moorDriverForPath(path);
    if (driver == null) {
      throw RequestFailure(plugin.RequestError(
          plugin.RequestErrorCode.INVALID_PARAMETER,
          "Path isn't covered by plugin: $path"));
    }
    return driver;
  }

  @override
  void contentChanged(String path) {
    _moorDriverForPath(path)?.handleFileChanged(path);
  }

  @override
  Future<AnalysisSetContextRootsResult> handleAnalysisSetContextRoots(
      AnalysisSetContextRootsParams parameters) {
    final roots = parameters.roots;
    final oldRoots = drivers.keys.toList();

    for (final contextRoot in roots) {
      if (!oldRoots.remove(contextRoot)) {
        // The context is new! Create a driver for it
        final driver = MoorDriver(
          resourceProvider,
          contextRoot: contextRoot.root,
          sdkPath: sdkManager.defaultSdkDirectory,
        );
        _didCreateDriver(driver);
        drivers[contextRoot] = driver;
      }
    }

    // All remaining contexts have been removed
    for (final removed in oldRoots) {
      drivers.remove(removed).dispose();
    }

    return Future.value(plugin.AnalysisSetContextRootsResult());
  }

  Future<FoundFile> _waitParsed(String path) async {
    final driver = _moorDriverOrFail(path);

    final file = await driver.waitFileParsed(path);
    if (file == null) {
      throw RequestFailure(plugin.RequestError(
          plugin.RequestErrorCode.PLUGIN_ERROR,
          'Unknown file: Neither Dart or moor: $path'));
    }

    return file;
  }

  void _checkIsMoorFile(FoundFile file) {
    if (file.type != FileType.moor) {
      throw RequestFailure(
        plugin.RequestError(plugin.RequestErrorCode.INVALID_PARAMETER,
            'Not a moor file: ${file.uri}'),
      );
    }
  }

  Future<MoorRequest> _createMoorRequest(String path) async {
    final file = await _waitParsed(path);
    _checkIsMoorFile(file);
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
  Future<void> sendHighlightsNotification(String path) async {
    final driver = _moorDriverForPath(path);
    if (driver == null) {
      channel.sendNotification(
          plugin.AnalysisHighlightsParams(path, []).toNotification());
      return;
    }

    final highlights = await driver.ideServices.highlight(path);

    channel.sendNotification(
        plugin.AnalysisHighlightsParams(path, highlights).toNotification());
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
    _checkIsMoorFile(file);

    return MoorCompletionRequest(parameters.offset, resourceProvider, file);
  }

  @override
  Future<plugin.EditGetAssistsResult> handleEditGetAssists(
      plugin.EditGetAssistsParams parameters) async {
    final driver = _moorDriverOrFail(parameters.file);
    final results = await driver.ideServices
        .assists(parameters.file, parameters.offset, parameters.length);

    return plugin.EditGetAssistsResult(results);
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
    _checkIsMoorFile(file);

    return MoorRequestAtPosition(
        file, parameters.length, parameters.offset, resourceProvider);
  }
}

final _ideExpando = Expando<MoorIde>();

extension on MoorDriver {
  MoorIde get ideServices {
    return _ideExpando[this] ??=
        MoorIde(session, _DriverBasedFileManagement(this));
  }
}

class _DriverBasedFileManagement implements IdeFileManagement {
  final MoorDriver driver;

  _DriverBasedFileManagement(this.driver);

  @override
  Uri fsPathToUri(String path) {
    return driver.backend.provider.pathContext.toUri(path);
  }

  @override
  Future<void> waitUntilParsed(String path) {
    return driver.waitFileParsed(path);
  }
}
