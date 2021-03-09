//@dart=2.9
import 'package:analyzer/dart/element/element.dart';

/// Inputs coming from an external system (such as the analyzer, the build
/// package, etc.) that will be further analyzed by moor.
abstract class Input {
  final String path;

  Input(this.path);
}

/// Input for Dart files that have already been analyzed.
class DartInput extends Input {
  final LibraryElement library;

  DartInput(String path, this.library) : super(path);
}

/// Input for a `.moor` file
class MoorInput extends Input {
  final String content;

  MoorInput(String path, this.content) : super(path);
}
