// @dart=2.9
import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:logging/logging.dart';

import 'backend.dart';

class StandaloneBackend extends Backend {
  final AnalysisContext context;

  StandaloneBackend(this.context);

  String pathOfUri(Uri uri) {
    final currentSession = context.currentSession;
    final path = currentSession.uriConverter.uriToPath(uri);

    return path;
  }

  @override
  Uri resolve(Uri base, String import) {
    final resolved = base.resolve(import);
    final uriConverter = context.currentSession.uriConverter;

    // Try to make uris consistent by going to path and back
    final path = uriConverter.uriToPath(resolved);
    if (path == null) return resolved;

    return uriConverter.pathToUri(path) ?? resolved;
  }

  BackendTask newTask(Uri entrypoint) =>
      _StandaloneBackendTask(this, entrypoint);
}

class _StandaloneBackendTask extends BackendTask {
  final StandaloneBackend backend;
  @override
  final Uri entrypoint;

  _StandaloneBackendTask(this.backend, this.entrypoint);

  @override
  Future<bool> exists(Uri uri) {
    final path = backend.pathOfUri(uri);
    return Future.value(
        backend.context.currentSession.resourceProvider.getFile(path).exists);
  }

  @override
  Logger get log => Logger.root;

  @override
  Future<String> readMoor(Uri uri) {
    final path = backend.pathOfUri(uri);
    if (path == null) return Future.error('Uri $uri could not be resolved');
    final resourceProvider = backend.context.currentSession.resourceProvider;

    return Future.value(resourceProvider.getFile(path).readAsStringSync());
  }

  @override
  Future<LibraryElement> resolveDart(Uri uri) async {
    final result =
        await backend.context.currentSession.getLibraryByUri2(uri.toString());
    if (result is LibraryElementResult) {
      return result.element;
    }

    throw NotALibraryException(uri);
  }

  @override
  Future<DartType> resolveTypeOf(Uri context, String dartExpression) async {
    final element = await resolveDart(context);
    // todo: Override so that we don't throw. We should support this properly.
    return element.typeProvider.dynamicType;
  }
}
