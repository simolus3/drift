import 'dart:convert';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart' hide log;
import 'package:build/build.dart' as build show log;
import 'package:logging/logging.dart';
import 'package:moor_generator/src/backends/backend.dart';
import 'package:moor_generator/src/backends/build/serialized_types.dart';

class BuildBackend extends Backend {
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
      _cachedResults[asset] =
          await library.session.getResolvedLibraryByElement(library);

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
    return result.getElementDeclaration(element) ??
        await super.loadElementDeclaration(element);
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
}
