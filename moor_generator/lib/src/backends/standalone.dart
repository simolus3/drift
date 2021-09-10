import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:logging/logging.dart';

import 'backend.dart';

class StandaloneBackend extends Backend {
  final AnalysisContext context;

  /// An overlay resource provider, which must also be used by the [context].
  ///
  /// This will be used to create artificial files used to resolve the type of
  /// Dart expressions.
  final OverlayResourceProvider provider;

  StandaloneBackend(this.context, this.provider);

  String? pathOfUri(Uri uri) {
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

    return Future.value(path != null &&
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
        await backend.context.currentSession.getLibraryByUri(uri.toString());
    if (result is LibraryElementResult) {
      return result.element;
    }

    throw NotALibraryException(uri);
  }

  @override
  Future<DartType> resolveTypeOf(
      Uri context, String dartExpression, Iterable<String> imports) async {
    // Create a fake file next to the content
    final provider = backend.provider;
    final path = backend.pathOfUri(context)!;
    final pathContext = provider.pathContext;
    final pathForTemp = pathContext.join(
        pathContext.dirname(path), 'moor_temp_${dartExpression.hashCode}.dart');

    final content = StringBuffer();
    for (final import in imports) {
      content.writeln('import "$import";');
    }
    content.writeln('var e = $dartExpression;');

    provider.setOverlay(
      pathForTemp,
      content: content.toString(),
      modificationStamp: DateTime.now().millisecondsSinceEpoch,
    );

    try {
      final result =
          await backend.context.currentSession.getResolvedLibrary(pathForTemp);

      if (result is! ResolvedLibraryResult) {
        throw CannotLoadTypeException(
            'Could not resolve temporary helper file');
      }

      final field = result.element.units.first.topLevelVariables.first;
      return field.type;
    } finally {
      provider.removeOverlay(pathForTemp);
    }
  }
}
