import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:logging/logging.dart';

/// The backend used by drift's analysis implementation to read files and access
/// the Dart analyzer.
abstract class DriftBackend {
  /// A logger through which drift's analyzer will emit internal warnings and
  /// debugging information.
  Logger get log;

  /// Resolves a uri and normalizes it into a format used by this backend.
  Uri resolveUri(Uri base, String uriString);

  /// Reads a file as string.
  Future<String> readAsString(Uri uri);

  Future<Uri> uriOfDart(Element element) async {
    return element.source!.uri;
  }

  bool get canReadDart;

  /// Resolves a Dart library by its uri.
  ///
  /// This should also be able to resolve SDK libraries.
  /// If no Dart library can be found under that uri, throws a
  /// [NotALibraryException].
  Future<LibraryElement> readDart(Uri uri);

  /// Loads the resolved AST node defining the given [element].
  ///
  /// Depending on how the analyzer is accessed, this may throw an exception if
  /// the resolved AST is not available.
  /// When the [element] does not have a syntactic representation in the AST,
  /// null is returned.
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

  /// Resolves the Dart element named [reference] in the [imports] of [context].
  Future<Element?> resolveTopLevelElement(
      Uri context, String reference, Iterable<Uri> imports);
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
