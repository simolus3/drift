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
      result.parsedFile.accept(visitor);

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
        }
      }
    }
  }
}

class _HighlightingVisitor extends RecursiveVisitor<void> {
  final HighlightsCollector collector;

  _HighlightingVisitor(this.collector);

  void _contribute(SyntacticEntity node, HighlightRegionType type) {
    final offset = node.firstPosition;
    final length = node.lastPosition - offset;
    collector.addRegion(offset, length, type);
  }

  @override
  void visitReference(Reference e) {
    _contribute(e, HighlightRegionType.INSTANCE_GETTER_REFERENCE);
  }

  @override
  void visitQueryable(Queryable e) {
    if (e is TableReference) {
      final tableToken = e.tableNameToken;
      if (tableToken != null) {
        _contribute(e, HighlightRegionType.TYPE_PARAMETER);
      }
    }
    visitChildren(e);
  }

  @override
  void visitCreateTableStatement(CreateTableStatement e) {
    _visitTableInducingStatement(e);
  }

  @override
  void visitCreateVirtualTableStatement(CreateVirtualTableStatement e) {
    _visitTableInducingStatement(e);
  }

  void _visitTableInducingStatement(TableInducingStatement e) {
    if (e.tableNameToken != null) {
      _contribute(e.tableNameToken, HighlightRegionType.CLASS);
    }

    visitChildren(e);
  }

  @override
  void visitColumnDefinition(ColumnDefinition e) {
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

    visitChildren(e);
  }

  @override
  void visitSetComponent(SetComponent e) {
    _contribute(e.column, HighlightRegionType.INSTANCE_SETTER_REFERENCE);
    visitChildren(e);
  }

  @override
  void visitMoorDeclaredStatement(DeclaredStatement e) {
    if (e.identifier != null) {
      _contribute(
          e.identifier, HighlightRegionType.TOP_LEVEL_FUNCTION_DECLARATION);
    }

    visitChildren(e);
  }

  @override
  void visitLiteral(Literal e) {
    if (e is NullLiteral) {
      _contribute(e, HighlightRegionType.BUILT_IN);
    } else if (e is NumericLiteral) {
      _contribute(e, HighlightRegionType.LITERAL_INTEGER);
    } else if (e is StringLiteral) {
      _contribute(e, HighlightRegionType.LITERAL_STRING);
    } else if (e is BooleanLiteral) {
      _contribute(e, HighlightRegionType.LITERAL_BOOLEAN);
    }
  }
}
