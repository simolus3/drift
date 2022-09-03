import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:logging/logging.dart';

abstract class DriftBackend {
  Logger get log;

  Uri resolveUri(Uri base, String uriString);

  Future<String> readAsString(Uri uri);

  Future<LibraryElement> readDart(Uri uri);
  Future<AstNode?> loadElementDeclaration(Element element);
}
