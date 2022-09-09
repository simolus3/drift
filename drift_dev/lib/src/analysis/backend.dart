import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:logging/logging.dart';

abstract class DriftBackend {
  Logger get log;

  Uri resolveUri(Uri base, String uriString);

  Future<String> readAsString(Uri uri);

  Future<LibraryElement> readDart(Uri uri);
  Future<AstNode?> loadElementDeclaration(Element element);
}

/// Thrown when attempting to read a Dart library from a file that's not a
/// library.
class NotALibraryException implements Exception {
  /// The uri of the file that was attempted to read.
  final Uri uri;

  NotALibraryException(this.uri);
}
