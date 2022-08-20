import 'dart:convert';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart' hide log;
import 'package:build/build.dart' as build show log;
import 'package:drift_dev/src/analyzer/options.dart';
import 'package:drift_dev/src/backends/backend.dart';
import 'package:logging/logging.dart';

import '../../analysis/runner/preprocess_drift.dart';

class BuildBackend extends Backend {
  final DriftOptions options;

  BuildBackend([this.options = const DriftOptions.defaults()]);

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

  BuildBackendTask(this.step, this.backend);

  @override
  Uri get entrypoint => step.inputId.uri;

  AssetId _resolve(Uri uri) {
    return AssetId.resolve(uri, from: step.inputId);
  }

  @override
  Future<AstNode?> loadElementDeclaration(Element element) async {
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
  Future<Expression> resolveExpression(
      Uri context, String dartExpression, Iterable<String> imports) async {
    // we try to detect all calls of resolveTypeOf in an earlier builder and
    // prepare the result. See PreprocessBuilder for details
    final preparedHelperFile =
        _resolve(context).changeExtension('.drift_prep.json');
    final temporaryFile = _resolve(context).changeExtension('.temp.dart');

    if (!await step.canRead(preparedHelperFile)) {
      throw CannotReadExpressionException('Generated helper file not found. '
          'Check the build log for earlier errors.');
    }

    // todo: Cache this step?
    final content = await step.readAsString(preparedHelperFile);
    final json = DriftPreprocessorResult.fromJson(
        jsonDecode(content) as Map<String, Object?>);

    final fieldName = json.inlineDartExpressionsToHelperField[dartExpression];
    if (fieldName == null) {
      throw CannotReadExpressionException(
          'Generated helper file does not contain '
          '$dartExpression!');
    }

    final library = await step.resolver.libraryFor(temporaryFile);
    final field = library.units.first.topLevelVariables
        .firstWhere((element) => element.name == fieldName);
    final fieldAst = await step.resolver.astNodeFor(field, resolve: true);

    final initializer = (fieldAst as VariableDeclaration).initializer;
    if (initializer == null) {
      throw CannotReadExpressionException(
          'Malformed helper file, this should never happen');
    }
    return initializer;
  }
}
