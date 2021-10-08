import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:logging/logging.dart';

/// A backend for the moor generator.
///
/// Currently, we only have a backend based on the build package, but we can
/// extend this to a backend for an analyzer plugin or a standalone tool.
abstract class Backend {
  /// Resolves an [import] statement from the context of a [base] uri. This
  /// should support both relative and `package:` imports.
  ///
  /// Returns null if the url can't be resolved.
  Uri? resolve(Uri base, String import);
}

/// Used to analyze a single file via ([entrypoint]). The other methods can be
/// used to read imports used by the other files.
abstract class BackendTask {
  Uri get entrypoint;
  Logger get log;

  /// Resolve the Dart library at [uri].
  ///
  /// If the file at [uri] isn't a library, for instance because it's a part
  /// file, throws a [NotALibraryException].
  Future<LibraryElement> resolveDart(Uri uri);

  Future<String> readMoor(Uri uri);

  /// Resolves the type of a Dart expression given as a string.
  ///
  /// [context] is a file in which the expression should be resolved, which is
  /// relevant for relevant imports. [imports] is a list of (relative) imports
  /// which may be used to resolve the expression.
  ///
  /// Throws a [CannotLoadTypeException] when the type could not be resolved.
  Future<DartType> resolveTypeOf(
      Uri context, String dartExpression, Iterable<String> imports) {
    throw CannotLoadTypeException('Resolving dart expressions not supported');
  }

  Future<AstNode?> loadElementDeclaration(Element element) async {
    final library = element.library;
    if (library == null) return null;

    final info = await library.session.getResolvedLibraryByElement(library);
    if (info is ResolvedLibraryResult) {
      return info.getElementDeclaration(element)?.node;
    } else {
      return null;
    }
  }

  /// Checks whether a file at [uri] exists.
  Future<bool> exists(Uri uri);

  /// Used from the higher-level api to notify the backend that a file would
  /// have been read, but hasn't due to caching.
  ///
  /// We use this so that the build package can generate the dependency graph
  /// correctly.
  Future<void> fakeRead(Uri uri) async {}
}

/// Thrown when attempting to read a Dart library from a file that's not a
/// library.
class NotALibraryException implements Exception {
  /// The uri of the file that was attempted to read.
  final Uri uri;

  NotALibraryException(this.uri);
}

class CannotLoadTypeException implements Exception {
  final String msg;

  CannotLoadTypeException(this.msg);
}
