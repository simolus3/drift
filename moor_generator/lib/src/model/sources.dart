//@dart=2.9
import 'package:analyzer/dart/element/element.dart';
import 'package:moor_generator/src/analyzer/runner/file_graph.dart';
import 'package:sqlparser/sqlparser.dart';

/// Represents a single location accessible to analysis services.
class SourceLocation {
  final FoundFile file;
  final int offset;

  SourceLocation(this.file, this.offset);
}

/// Represents a range in a source file, accessible to analysis services
class SourceRange {
  final SourceLocation start;
  final int length;
  SourceLocation _end;

  FoundFile get file => start.file;

  SourceLocation get end {
    return _end ??= SourceLocation(start.file, start.offset + length);
  }

  SourceRange(this.start, this.length);

  factory SourceRange.fromElementAndFile(Element element, FoundFile file) {
    return SourceRange(
      SourceLocation(file, element.nameOffset),
      element.nameLength,
    );
  }

  factory SourceRange.fromNodeAndFile(AstNode node, FoundFile file) {
    return SourceRange(
      SourceLocation(file, node.firstPosition),
      node.length,
    );
  }
}
