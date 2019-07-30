import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/utilities/highlights/highlights.dart';

import '../results.dart';

class MoorHighlightingRequest extends HighlightsRequest {
  @override
  final String path;
  @override
  final ResourceProvider resourceProvider;
  final MoorAnalysisResults parsedFile;

  MoorHighlightingRequest(this.parsedFile, this.path, this.resourceProvider);
}
