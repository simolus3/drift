//@dart=2.9
import 'dart:convert';
import 'package:analyzer/dart/ast/ast.dart';
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

  BuildBackend([this.options = const MoorOptions.defaults()]);

  BuildBackendTask createTask(BuildStep step) {
    return BuildBackendTask(step, this);
  }

  @override
  Uri resolve(Uri base, String import) {
    final from = AssetId.resolve(base);
    return AssetId.resolve(Uri.parse(import), from: from).uri;
  }
}

class BuildBackendTask extends BackendTask {
  final BuildStep step;
  final BuildBackend backend;
  final TypeDeserializer typeDeserializer;

  BuildBackendTask(this.step, this.backend)
      : typeDeserializer = TypeDeserializer(step);

  @override
  Uri get entrypoint => step.inputId.uri;

  AssetId _resolve(Uri uri) {
    return AssetId.resolve(uri, from: step.inputId);
  }

  @override
  Future<AstNode> loadElementDeclaration(Element element) async {
    return await step.resolver.astNodeFor(element, resolve: true);
  }

  @override
  Future<String> readMoor(Uri uri) {
    return step.readAsString(_resolve(uri));
  }

  @override
  Future<LibraryElement> resolveDart(Uri uri) async {
    try {
      final asset = _resolve(uri);
      return await step.resolver.libraryFor(asset);
    } on NonLibraryAssetException catch (_) {
      throw NotALibraryException(uri);
    }
  }

  @override
  Logger get log => build.log;

  @override
  Future<bool> exists(Uri uri) {
    return step.canRead(_resolve(uri));
  }

  @override
  Future<DartType> resolveTypeOf(
      Uri context, String dartExpression, Iterable<String> imports) async {
    // we try to detect all calls of resolveTypeOf in an earlier builder and
    // prepare the result. See PreprocessBuilder for details
    final preparedHelperFile =
        _resolve(context).changeExtension('.dart_in_moor');

    if (!await step.canRead(preparedHelperFile)) {
      throw CannotLoadTypeException('Generated helper file not found. '
          'Check the build log for earlier errors.');
    }

    final content = await step.readAsString(preparedHelperFile);
    final json = jsonDecode(content) as Map<String, dynamic>;
    final serializedType = json[dartExpression] as Map<String, dynamic>;

    return typeDeserializer
        .deserialize(SerializedType.fromJson(serializedType));
  }
}
