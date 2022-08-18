import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:drift_dev/moor_generator.dart';
import 'package:drift_dev/src/analyzer/runner/file_graph.dart';
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
    endLine: last.line + 1,
    endColumn: last.column + 1,
  );
}

Location? locationOfNode(FoundFile file, AstNode node) {
  if (!node.hasSpan) return null;

  final span = node.span;
  return span != null ? _locationForSpan(span, file) : null;
}

Location? locationOfDeclaration(Declaration declaration) {
  final file = declaration.declaration.file;
  if (declaration is DartDeclaration) {
    return _locationForSpan(spanForElement(declaration.element), file);
  } else if (declaration is DriftFileDeclaration) {
    return locationOfNode(file, declaration.node);
  }

  return null;
}
