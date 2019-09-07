import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/highlights/highlights.dart';
import 'package:moor_generator/src/backends/plugin/services/highlights/request.dart';
import 'package:sqlparser/sqlparser.dart';

const _notBuiltIn = {
  TokenType.numberLiteral,
  TokenType.stringLiteral,
  TokenType.identifier,
  TokenType.leftParen,
  TokenType.rightParen,
  TokenType.comma,
  TokenType.star,
  TokenType.less,
  TokenType.lessEqual,
  TokenType.lessMore,
  TokenType.equal,
  TokenType.more,
  TokenType.moreEqual,
  TokenType.shiftRight,
  TokenType.shiftLeft,
  TokenType.exclamationEqual,
  TokenType.plus,
  TokenType.minus,
};

class SqlHighlighter implements HighlightsContributor {
  const SqlHighlighter();

  @override
  void computeHighlights(
      HighlightsRequest request, HighlightsCollector collector) {
    if (request is! MoorHighlightingRequest) {
      return;
    }

    final typedRequest = request as MoorHighlightingRequest;
    final visitor = _HighlightingVisitor(collector);

    final result = typedRequest.task.lastResult;

    for (var stmt in result.statements) {
      stmt.accept(visitor);
    }

    for (var token in result.tokens) {
      if (!_notBuiltIn.contains(token.type)) {
        final start = token.span.start.offset;
        final length = token.span.length;
        collector.addRegion(start, length, HighlightRegionType.BUILT_IN);
      }
    }
  }
}

class _HighlightingVisitor extends RecursiveVisitor<void> {
  final HighlightsCollector collector;

  _HighlightingVisitor(this.collector);

  void _contribute(AstNode node, HighlightRegionType type) {
    final offset = node.firstPosition;
    final length = node.lastPosition - offset;
    collector.addRegion(offset, length, type);
  }

  @override
  void visitReference(Reference e) {
    _contribute(e, HighlightRegionType.INSTANCE_FIELD_REFERENCE);
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
