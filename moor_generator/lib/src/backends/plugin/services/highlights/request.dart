import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/utilities/highlights/highlights.dart';
import 'package:moor_generator/src/analyzer/session.dart';

class MoorHighlightingRequest extends HighlightsRequest {
  @override
  final String path;
  @override
  final ResourceProvider resourceProvider;
  final MoorTask task;

  MoorHighlightingRequest(this.task, this.path, this.resourceProvider);
}
