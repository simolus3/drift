import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/utilities/folding/folding.dart';
import 'package:analyzer_plugin/utilities/highlights/highlights.dart';
import 'package:analyzer_plugin/utilities/outline/outline.dart';
import 'package:moor_generator/src/analyzer/session.dart';

class MoorRequest implements OutlineRequest, HighlightsRequest, FoldingRequest {
  final MoorTask resolvedTask;
  @override
  final ResourceProvider resourceProvider;

  MoorRequest(this.resolvedTask, this.resourceProvider);

  @override
  String get path => resolvedTask.backendTask.entrypoint.toFilePath();
}
