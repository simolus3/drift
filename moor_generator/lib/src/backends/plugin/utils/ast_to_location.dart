import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:moor_generator/src/analyzer/runner/file_graph.dart';
import 'package:sqlparser/sqlparser.dart';

Location locationOfNode(FoundFile file, AstNode node) {
  if (!node.hasSpan) return null;

  final first = node.first.span.start;
  final last = node.last.span.end;

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
