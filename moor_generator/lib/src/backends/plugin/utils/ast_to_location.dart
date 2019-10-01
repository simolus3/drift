import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:moor_generator/src/analyzer/runner/file_graph.dart';
import 'package:moor_generator/src/analyzer/sql_queries/meta/declarations.dart';
import 'package:source_gen/source_gen.dart' show spanForElement;
import 'package:source_span/source_span.dart';
import 'package:sqlparser/sqlparser.dart';

Location _locationForSpan(SourceSpan span, FoundFile file) {
  final first = span.start;
  final last = span.end;

  // in [Location], lines and columns are one-indexed, but in [SourceLocation]
  // they're 0-based.
  return Location(
    file.uri.path,
    first.offset,
    last.offset - first.offset,
    first.line + 1,
    first.column + 1,
  );
}

Location locationOfNode(FoundFile file, AstNode node) {
  if (!node.hasSpan) return null;
  return _locationForSpan(node.span, file);
}

Location locationOfDeclaration(BaseDeclaration declaration) {
  if (declaration.dartDeclaration != null) {
    final span = spanForElement(declaration.dartDeclaration);
    return _locationForSpan(span, declaration.declarationFile);
  } else if (declaration.moorDeclaration != null) {
    return locationOfNode(
        declaration.declarationFile, declaration.moorDeclaration);
  }
  return null;
}
