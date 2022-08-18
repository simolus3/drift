import 'package:analyzer/dart/element/element.dart';

/// Inputs coming from an external system (such as the analyzer, the build
/// package, etc.) that will be further analyzed by drift_dev.
abstract class Input {
  final String path;

  Input(this.path);
}

/// Input for Dart files that have already been analyzed.
class DartInput extends Input {
  final LibraryElement library;

  DartInput(String path, this.library) : super(path);
}

/// Input for a `.drift` file
class DriftFileInput extends Input {
  final String content;

  DriftFileInput(String path, this.content) : super(path);
}
