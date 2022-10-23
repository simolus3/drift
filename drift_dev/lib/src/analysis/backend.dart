import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:logging/logging.dart';

abstract class DriftBackend {
  Logger get log;

  Uri resolveUri(Uri base, String uriString);

  Future<String> readAsString(Uri uri);

  Future<Uri> uriOfDart(Element element) async {
    return element.source!.uri;
  }

  Future<LibraryElement> readDart(Uri uri);
  Future<AstNode?> loadElementDeclaration(Element element);

  /// Resolves a Dart expression from a string.
  ///
  /// [context] is a file in which the expression should be resolved, which is
  /// relevant for relevant imports. [imports] is a list of (relative) imports
  /// which may be used to resolve the expression.
  ///
  /// Throws a [CannotReadExpressionException] if the type could not be
  /// resolved.
  Future<Expression> resolveExpression(
      Uri context, String dartExpression, Iterable<String> imports);
}

/// Thrown when attempting to read a Dart library from a file that's not a
/// library.
class NotALibraryException implements Exception {
  /// The uri of the file that was attempted to read.
  final Uri uri;

  NotALibraryException(this.uri);
}

class CannotReadExpressionException implements Exception {
  final String msg;

  CannotReadExpressionException(this.msg);

  @override
  String toString() {
    return 'Could not read expression: $msg';
  }
}
