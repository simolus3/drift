import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';

import 'logger.dart';

class DriftPlugin extends ServerPlugin {
  DriftPlugin(ResourceProvider provider) : super(resourceProvider: provider) {
    setupLogger(this);
  }

  factory DriftPlugin.forProduction() {
    return DriftPlugin(PhysicalResourceProvider.INSTANCE);
  }

  @override
  List<String> get fileGlobsToAnalyze => const ['*.moor', '*.drift', '*.dart'];
  @override
  String get name => 'Drift plugin';
  @override
  // docs say that this should a version of _this_ plugin, but they lie. this
  // version will be used to determine compatibility with the analyzer
  String get version => '4.4.1';
  @override
  String get contactInfo =>
      'Create an issue at https://github.com/simolus3/drift/';

  @override
  Future<void> analyzeFile(
      {required AnalysisContext analysisContext, required String path}) async {}
}
