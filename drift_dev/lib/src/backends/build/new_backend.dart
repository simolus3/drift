import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:logging/logging.dart';
import 'package:build/build.dart';
import 'package:build/build.dart' as build;

import '../../analysis/backend.dart';

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
  Future<LibraryElement> readDart(Uri uri) {
    return _buildStep.resolver.libraryFor(AssetId.resolve(uri));
  }

  @override
  Future<AstNode?> loadElementDeclaration(Element element) {
    return _buildStep.resolver.astNodeFor(element, resolve: true);
  }
}
