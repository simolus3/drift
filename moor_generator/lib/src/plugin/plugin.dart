import 'package:analyzer/file_system/file_system.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';

class MoorPlugin extends ServerPlugin {
  MoorPlugin(ResourceProvider provider) : super(provider);

  @override
  final List<String> fileGlobsToAnalyze = const ['**/*.moor'];
  @override
  final String name = 'Moor plugin';
  @override
  final String version = '0.0.1';
  @override
  final String contactInfo =
      'Create an issue at https://github.com/simolus3/moor/';

  @override
  AnalysisDriverGeneric createAnalysisDriver(ContextRoot contextRoot) {
    return null;
  }
}
