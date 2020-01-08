import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/highlights/highlights.dart';
import 'package:moor_generator/src/backends/plugin/services/requests.dart';
import 'package:sqlparser/sqlparser.dart';

class MoorHighlightContributor implements HighlightsContributor {
  const MoorHighlightContributor();

  @override
  void computeHighlights(
      HighlightsRequest request, HighlightsCollector collector) {
    if (request is! MoorRequest) {
      return;
    }

    final typedRequest = request as MoorRequest;
    if (typedRequest.isMoorAndParsed) {
      final result = typedRequest.parsedMoor;

      final visitor = _HighlightingVisitor(collector);
      result.parsedFile.acceptWithoutArg(visitor);

      for (final token in result.parseResult.tokens) {
        final start = token.span.start.offset;
        final length = token.span.length;

        if (token is KeywordToken && !token.isIdentifier) {
          collector.addRegion(start, length, HighlightRegionType.BUILT_IN);
        } else if (token is CommentToken) {
          final mode = const {
            CommentMode.cStyle: HighlightRegionType.COMMENT_BLOCK,
            CommentMode.line: HighlightRegionType.COMMENT_END_OF_LINE,
          }[token];
          collector.addRegion(start, length, mode);
        } else if (token is InlineDartToken) {
          collector.addRegion(start, length, HighlightRegionType.ANNOTATION);
        } else if (token is VariableToken) {
          collector.addRegion(
              start, length, HighlightRegionType.PARAMETER_REFERENCE);
        } else if (token is StringLiteralToken) {
          collector.addRegion(
              start, length, HighlightRegionType.LITERAL_STRING);
        }
      }
    }
  }
}

class _HighlightingVisitor extends RecursiveVisitor<void, void> {
  final HighlightsCollector collector;

  _HighlightingVisitor(this.collector);

  void _contribute(SyntacticEntity node, HighlightRegionType type) {
    final offset = node.firstPosition;
    final length = node.lastPosition - offset;
    collector.addRegion(offset, length, type);
  }

  @override
  void visitReference(Reference e, void arg) {
    _contribute(e, HighlightRegionType.INSTANCE_GETTER_REFERENCE);
  }

  @override
  void visitQueryable(Queryable e, void arg) {
    if (e is TableReference) {
      final tableToken = e.tableNameToken;
      if (tableToken != null) {
        _contribute(e, HighlightRegionType.TYPE_PARAMETER);
      }
    }
    visitChildren(e, arg);
  }

  @override
  void visitTableInducingStatement(TableInducingStatement e, void arg) {
    if (e.tableNameToken != null) {
      _contribute(e.tableNameToken, HighlightRegionType.CLASS);
    }

    visitChildren(e, arg);
  }

  @override
  void visitColumnDefinition(ColumnDefinition e, void arg) {
    final nameToken = e.nameToken;
    if (nameToken != null) {
      _contribute(nameToken, HighlightRegionType.INSTANCE_FIELD_DECLARATION);
    }

    final typeTokens = e.typeNames;
    if (typeTokens != null && typeTokens.isNotEmpty) {
      final first = typeTokens.first.firstPosition;
      final last = typeTokens.last.lastPosition;
      final length = last - first;
      collector.addRegion(first, length, HighlightRegionType.TYPE_PARAMETER);
    }

    visitChildren(e, arg);
  }

  @override
  void visitSetComponent(SetComponent e, void arg) {
    _contribute(e.column, HighlightRegionType.INSTANCE_SETTER_REFERENCE);
    visitChildren(e, arg);
  }

  @override
  void visitMoorDeclaredStatement(DeclaredStatement e, void arg) {
    final identifier = e.identifier;
    if (identifier is SimpleName && identifier.identifier != null) {
      _contribute(identifier.identifier,
          HighlightRegionType.TOP_LEVEL_FUNCTION_DECLARATION);
    } else if (identifier is SpecialStatementIdentifier &&
        identifier.nameToken != null) {
      _contribute(identifier.nameToken, HighlightRegionType.ANNOTATION);
    }

    visitChildren(e, arg);
  }

  @override
  void visitLiteral(Literal e, void arg) {
    if (e is NullLiteral) {
      _contribute(e, HighlightRegionType.BUILT_IN);
    } else if (e is NumericLiteral) {
      _contribute(e, HighlightRegionType.LITERAL_INTEGER);
    } else if (e is BooleanLiteral) {
      _contribute(e, HighlightRegionType.LITERAL_BOOLEAN);
    }
    // string literals are reported for each string token
  }
}
