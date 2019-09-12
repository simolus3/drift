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

      for (var token in result.parseResult.tokens) {
        if (token is KeywordToken && !token.isIdentifier) {
          final start = token.span.start.offset;
          final length = token.span.length;
          collector.addRegion(start, length, HighlightRegionType.BUILT_IN);
        }
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
