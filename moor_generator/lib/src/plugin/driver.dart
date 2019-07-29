// ignore_for_file: implementation_imports
import 'package:analyzer/src/dart/analysis/driver.dart';

class MoorDriver implements AnalysisDriverGeneric {
  final _addedFiles = <String>{};

  bool _ownsFile(String path) => path.endsWith('.moor');

  @override
  void addFile(String path) {
    if (_ownsFile(path)) {
      _addedFiles.add(path);
      handleFileChanged(path);
    }
  }

  @override
  void dispose() {}

  void handleFileChanged(String path) {
    if (_ownsFile(path)) {}
  }

  @override
  bool get hasFilesToAnalyze => null;

  @override
  Future<void> performWork() {
    // TODO: implement performWork
    return null;
  }

  @override
  set priorityFiles(List<String> priorityPaths) {
    // We don't support this ATM
  }

  @override
  AnalysisDriverPriority get workPriority => AnalysisDriverPriority.general;
}
