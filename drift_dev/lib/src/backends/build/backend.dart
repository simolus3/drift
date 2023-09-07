import 'dart:convert';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:drift_dev/src/analysis/driver/state.dart';
import 'package:drift_dev/src/analysis/results/element.dart';
import 'package:logging/logging.dart';
import 'package:build/build.dart';
import 'package:build/build.dart' as build;

import '../../analysis/backend.dart';
import '../../analysis/driver/driver.dart';
import '../../analysis/preprocess_drift.dart';
import '../../analysis/resolver/dart/helper.dart';

class DriftBuildBackend extends DriftBackend {
  final BuildStep _buildStep;

  DriftBuildBackend(this._buildStep);

  @override
  Logger get log => build.log;

  @override
  Uri resolveUri(Uri base, String uriString) {
    return AssetId.resolve(Uri.parse(uriString), from: AssetId.resolve(base))
        .uri;
  }

  @override
  Future<String> readAsString(Uri uri) {
    return _buildStep.readAsString(AssetId.resolve(uri));
  }

  @override
  Future<Uri> uriOfDart(Element element) async {
    final id = await _buildStep.resolver.assetIdForElement(element);
    return id.uri;
  }

  @override
  Future<LibraryElement> readDart(Uri uri) async {
    if (uri.scheme == 'dart') {
      final name = 'dart.${uri.path}';
      final library = await _buildStep.resolver.findLibraryByName(name);

      if (library == null) {
        throw NotALibraryException(uri);
      } else {
        return library;
      }
    }

    try {
      return await _buildStep.resolver.libraryFor(AssetId.resolve(uri));
    } on NonLibraryAssetException {
      throw NotALibraryException(uri);
    }
  }

  @override
  Future<AstNode?> loadElementDeclaration(Element element) {
    return _buildStep.resolver.astNodeFor(element, resolve: true);
  }

  @override
  Future<Expression> resolveExpression(
      Uri context, String dartExpression, Iterable<String> imports) async {
    final original = AssetId.resolve(context);
    final tempDart = original.changeExtension('.expr.temp.dart');
    final prepJson = original.changeExtension('.drift_prep.json');

    DriftPreprocessorResult prepResult;
    try {
      prepResult = DriftPreprocessorResult.fromJson(
          json.decode(await _buildStep.readAsString(prepJson))
              as Map<String, Object?>);
    } on Exception catch (e, s) {
      log.warning('Could not read Dart expression $dartExpression', e, s);
      throw CannotReadExpressionException('Could not load helpers');
    }

    final getter =
        prepResult.inlineDartExpressionsToHelperField[dartExpression];
    if (getter == null) {
      throw CannotReadExpressionException('No field for $dartExpression');
    }

    final library = await _buildStep.resolver.libraryFor(tempDart);
    final field = library.units.first.topLevelVariables
        .firstWhere((element) => element.name == getter);
    final fieldAst = await _buildStep.resolver.astNodeFor(field, resolve: true);

    final initializer = (fieldAst as VariableDeclaration).initializer;
    if (initializer == null) {
      throw CannotReadExpressionException(
          'Malformed helper file, this should never happen');
    }
    return initializer;
  }

  @override
  Future<Element?> resolveTopLevelElement(
      Uri context, String reference, Iterable<Uri> imports) async {
    final original = AssetId.resolve(context);
    final tempDart = original.changeExtension('.expr.temp.dart');

    if (await _buildStep.canRead(tempDart)) {
      final library = await _buildStep.resolver.libraryFor(tempDart);

      return library.scope.lookup(reference).getter;
    } else {
      // If there's no temporary file whose imports we can use, then that means
      // that there aren't any Dart imports in [context] at all. So we just need
      // to look it up in `dart:core`.
      // For that, resolve a library we know exists and likely has been resolved
      // already.
      final libraryWeKnowExists = await _buildStep.resolver
          .libraryFor(AssetId.resolve(KnownDriftTypes.uri));
      final dartCore = libraryWeKnowExists.typeProvider.objectElement.library;

      return dartCore.exportNamespace.get(reference);
    }
  }
}

class BuildCacheReader implements AnalysisResultCacheReader {
  final BuildStep _buildStep;

  @override
  final bool findsLocalElementsReliably;
  @override
  final bool findsResolvedElementsReliably;

  BuildCacheReader(
    this._buildStep, {
    this.findsLocalElementsReliably = false,
    this.findsResolvedElementsReliably = false,
  });

  @override
  Future<CachedDiscoveryResults?> readDiscovery(Uri uri) async {
    // For the format, see the `DriftDiscover` builder in `analyzer.dart`.
    final assetId = AssetId.resolve(uri).addExtension('.drift_elements.json');

    if (await _buildStep.canRead(assetId)) {
      final results = json.decode(await _buildStep.readAsString(assetId));
      final rawImports = results['imports'] as List;
      final rawElements = (results['elements'] as List).cast<Map>();

      return CachedDiscoveryResults(
        results['valid_import'] as bool,
        [
          for (final import in rawImports.cast<Map<String, Object?>>())
            (
              uri: Uri.parse(import['uri'] as String),
              transitive: import['transitive'] as bool,
            )
        ],
        [
          for (final element in rawElements)
            ExistingDriftElement(
              ownId: DriftElementId(uri, element['name'] as String),
              kind: DriftElementKind.byName[element['kind']]!,
              dartElementName: element['dart_name'] as String?,
            ),
        ],
      );
    }

    return null;
  }

  @override
  Future<String?> readElementCacheFor(Uri uri) async {
    // These files are generated by the `DriftAnalyzer` builder
    final assetId = AssetId.resolve(uri).addExtension('.drift_module.json');
    if (await _buildStep.canRead(assetId)) {
      return _buildStep.readAsString(assetId);
    }

    return null;
  }

  @override
  Future<LibraryElement?> readTypeHelperFor(Uri uri) async {
    final assetId = AssetId.resolve(uri).addExtension('.types.temp.dart');
    if (await _buildStep.canRead(assetId)) {
      return _buildStep.resolver.libraryFor(assetId, allowSyntaxErrors: true);
    }

    return null;
  }
}
