import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:logging/logging.dart';

import '../analysis/backend.dart';
import '../analysis/driver/driver.dart';
import '../analysis/driver/state.dart';
import '../analysis/options.dart';

class PhysicalDriftDriver {
  final DriftAnalysisDriver driver;
  final AnalysisContextBackend _backend;

  PhysicalDriftDriver(this.driver, this._backend);

  Uri uriFromPath(String path) {
    final pathUri = _backend.provider.pathContext.toUri(path);

    // Normalize to package URI if necessary.
    return _backend.resolveUri(pathUri, '');
  }

  Future<FileState> analyzeElementsForPath(String path) {
    return driver.resolveElements(uriFromPath(path));
  }
}

/// A drift analysis backend deferring Dart analysis to the given [context].
class AnalysisContextBackend extends DriftBackend {
  @override
  final Logger log = Logger('drift.analysis');

  final AnalysisContext context;

  /// An overlay resource provider, which must also be used by the [context].
  ///
  /// This will be used to create artificial files used to resolve the type of
  /// Dart expressions.
  final OverlayResourceProvider provider;

  AnalysisContextBackend(this.context, this.provider);

  static Future<PhysicalDriftDriver> createDriver({
    DriftOptions options = const DriftOptions.defaults(),
    ResourceProvider? resourceProvider,
    required String projectDirectory,
  }) async {
    final underlyingProvider =
        resourceProvider ?? PhysicalResourceProvider.INSTANCE;
    final provider = OverlayResourceProvider(underlyingProvider);

    final contextCollection = AnalysisContextCollection(
      includedPaths: [projectDirectory],
      resourceProvider: provider,
    );
    final context = contextCollection.contextFor(projectDirectory);

    final backend = AnalysisContextBackend(context, provider);
    final driver = DriftAnalysisDriver(backend, options);
    return PhysicalDriftDriver(driver, backend);
  }

  String? _pathOfUri(Uri uri) {
    final currentSession = context.currentSession;
    final path = currentSession.uriConverter.uriToPath(uri);

    return path;
  }

  @override
  Future<AstNode?> loadElementDeclaration(Element element) async {
    final library = element.library;
    if (library == null) return null;

    final info =
        await context.currentSession.getResolvedLibraryByElement(library);
    if (info is ResolvedLibraryResult) {
      return info.getElementDeclaration(element)?.node;
    } else {
      return null;
    }
  }

  @override
  Future<String> readAsString(Uri uri) {
    final path = _pathOfUri(uri);
    if (path == null) return Future.error('Uri $uri could not be resolved');
    final resourceProvider = context.currentSession.resourceProvider;

    return Future.value(resourceProvider.getFile(path).readAsStringSync());
  }

  @override
  bool get canReadDart => true;

  @override
  Future<LibraryElement> readDart(Uri uri) async {
    final result = await context.currentSession.getLibraryByUri(uri.toString());
    if (result is LibraryElementResult) {
      return result.element;
    }

    throw NotALibraryException(uri);
  }

  @override
  Future<Expression> resolveExpression(
      Uri context, String dartExpression, Iterable<String> imports) async {
    // Create a fake file next to the content
    final path = _pathOfUri(context)!;
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
          await this.context.currentSession.getResolvedLibrary(pathForTemp);

      if (result is! ResolvedLibraryResult) {
        throw CannotReadExpressionException(
            'Could not resolve temporary helper file');
      }

      final compilationUnit = result.units.first.unit;

      for (final member in compilationUnit.declarations) {
        if (member is TopLevelVariableDeclaration) {
          return member.variables.variables.first.initializer!;
        }
      }

      throw CannotReadExpressionException(
          'Temporary helper file contains no field.');
    } finally {
      provider.removeOverlay(pathForTemp);
    }
  }

  @override
  Future<Element?> resolveTopLevelElement(
      Uri context, String reference, Iterable<Uri> imports) async {
    // Create a fake file next to the content
    final path = _pathOfUri(context)!;
    final pathContext = provider.pathContext;
    final pathForTemp = pathContext.join(
        pathContext.dirname(path), 'moor_temp_${imports.hashCode}.dart');

    final content = StringBuffer();
    for (final import in imports) {
      content.writeln('import "$import";');
    }

    provider.setOverlay(
      pathForTemp,
      content: content.toString(),
      modificationStamp: DateTime.now().millisecondsSinceEpoch,
    );

    try {
      final result =
          await this.context.currentSession.getResolvedLibrary(pathForTemp);

      if (result is ResolvedLibraryResult) {
        return result.element.definingCompilationUnit.scope
            .lookup(reference)
            .getter;
      }
    } finally {
      provider.removeOverlay(path);
    }

    return null;
  }

  @override
  Uri resolveUri(Uri base, String uriString) {
    final resolved = base.resolve(uriString);
    final uriConverter = context.currentSession.uriConverter;

    // Try to make uris consistent by going to path and back
    final path = uriConverter.uriToPath(resolved);
    if (path == null) return resolved;

    return uriConverter.pathToUri(path) ?? resolved;
  }
}
