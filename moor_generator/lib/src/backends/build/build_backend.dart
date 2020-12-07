import 'dart:convert';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart' hide log;
import 'package:build/build.dart' as build show log;
import 'package:logging/logging.dart';
import 'package:moor_generator/src/analyzer/options.dart';
import 'package:moor_generator/src/backends/backend.dart';
import 'package:moor_generator/src/backends/build/serialized_types.dart';

class BuildBackend extends Backend {
  final MoorOptions options;

  BuildBackend([this.options = const MoorOptions()]);

  BuildBackendTask createTask(BuildStep step) {
    return BuildBackendTask(step, this);
  }

  @override
  Uri resolve(Uri base, String import) {
    final from = AssetId.resolve(base.toString());
    return AssetId.resolve(import, from: from).uri;
  }
}

class BuildBackendTask extends BackendTask {
  final BuildStep step;
  final BuildBackend backend;
  final TypeDeserializer typeDeserializer;

  final Map<AssetId, ResolvedLibraryResult> _cachedResults = {};

  /// The analysis session might be invalidated every time we resolve a new
  /// library, so we grab a new one instead of using `LibraryElement.session`.
  AnalysisSession _currentAnalysisSession;

  BuildBackendTask(this.step, this.backend)
      : typeDeserializer = TypeDeserializer(step);

  @override
  Uri get entrypoint => step.inputId.uri;

  AssetId _resolve(Uri uri) {
    return AssetId.resolve(uri.toString(), from: step.inputId);
  }

  @override
  Future<String> readMoor(Uri uri) {
    return step.readAsString(_resolve(uri));
  }

  @override
  Future<LibraryElement> resolveDart(Uri uri) async {
    try {
      final asset = _resolve(uri);
      final library = await step.resolver.libraryFor(asset);
      _currentAnalysisSession = library.session;

      return library;
    } on NonLibraryAssetException catch (_) {
      throw NotALibraryException(uri);
    }
  }

  @override
  Future<ElementDeclarationResult> loadElementDeclaration(
      Element element) async {
    // prefer to use a cached value in case the session changed because another
    // dart file was read...
    final assetId = await step.resolver.assetIdForElement(element);
    final result = _cachedResults[assetId];

    if (result != null) {
      return result.getElementDeclaration(element);
    } else {
      _currentAnalysisSession ??= element.session;

      for (var retries = 0; retries < _maxSessionRetries; retries++) {
        try {
          final library =
              await _libraryInCurrentSession(element.library, assetId);

          final result = await _currentAnalysisSession
              .getResolvedLibraryByElement(library);
          _cachedResults[assetId] = result;

          // Note: getElementDeclaration works by comparing source offsets, so
          // element.session != session is not a problem in this case.
          return result.getElementDeclaration(element);
        } on InconsistentAnalysisException {
          final isLastTry = retries == _maxSessionRetries - 1;
          if (isLastTry) rethrow;
        }
      }
    }
  }

  Future<LibraryElement> _libraryInCurrentSession(
      LibraryElement library, AssetId definingAsset) async {
    if (library.session == _currentAnalysisSession) return library;

    try {
      // This is safe: If this build step knows the library, it has already read
      // the originating asset. We can bypass the build asset reader!
      return await _currentAnalysisSession
          .getLibraryByUri(definingAsset.uri.toString());
    } on InconsistentAnalysisException {
      final library = await step.resolver.libraryFor(definingAsset);
      _currentAnalysisSession = library.session;
      return library;
    }
  }

  @override
  Logger get log => build.log;

  @override
  Future<bool> exists(Uri uri) {
    return step.canRead(_resolve(uri));
  }

  @override
  Future<DartType> resolveTypeOf(Uri context, String dartExpression) async {
    // we try to detect all calls of resolveTypeOf in an earlier builder and
    // prepare the result. See PreprocessBuilder for details
    final preparedHelperFile =
        _resolve(context).changeExtension('.dart_in_moor');

    if (!await step.canRead(preparedHelperFile)) {
      throw AssetNotFoundException(preparedHelperFile);
    }

    final content = await step.readAsString(preparedHelperFile);
    final json = jsonDecode(content) as Map<String, dynamic>;
    final serializedType = json[dartExpression] as Map<String, dynamic>;

    return typeDeserializer
        .deserialize(SerializedType.fromJson(serializedType));
  }

  static const int _maxSessionRetries = 5;
}
