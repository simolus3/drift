import 'package:analyzer/dart/element/element.dart';
import 'package:moor_generator/src/analyzer/session.dart';

/// A backend for the moor generator.
///
/// Currently, we only have a backend based on the build package, but we can
/// extend this to a backend for an analyzer plugin or a standalone tool.
abstract class Backend {
  final MoorSession session = MoorSession();
}

/// Used to analyze a single file via ([entrypoint]). The other methods can be
/// used to read imports used by the other files.
abstract class BackendTask {
  String get entrypoint;

  Future<LibraryElement> resolveDart(String path);
  Future<String> readMoor(String path);
}
