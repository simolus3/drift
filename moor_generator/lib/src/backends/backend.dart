import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:logging/logging.dart';
import 'package:moor_generator/src/analyzer/session.dart';

/// A backend for the moor generator.
///
/// Currently, we only have a backend based on the build package, but we can
/// extend this to a backend for an analyzer plugin or a standalone tool.
abstract class Backend {
  MoorSession _session;
  MoorSession get session => _session;

  Backend() {
    _session = MoorSession(this);
  }

  /// Resolves an [import] statement from the context of a [base] uri. This
  /// should support both relative and `package:` imports.
  Uri resolve(Uri base, String import);
}

/// Used to analyze a single file via ([entrypoint]). The other methods can be
/// used to read imports used by the other files.
abstract class BackendTask {
  Uri get entrypoint;
  Logger get log;

  Future<LibraryElement> resolveDart(Uri uri);

  Future<String> readMoor(Uri uri);

  Future<DartType> resolveTypeOf(Uri context, String dartExpression) {
    throw UnsupportedError('Resolving dart expressions not supported');
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
