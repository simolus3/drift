import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/folding/folding.dart';
import 'package:moor_generator/src/backends/plugin/services/requests.dart';
import 'package:sqlparser/sqlparser.dart';

class MoorFoldingContributor implements FoldingContributor {
  const MoorFoldingContributor();

  @override
  void computeFolding(FoldingRequest request, FoldingCollector collector) {
    final moorRequest = request as MoorRequest;

    final visitor = _FoldingVisitor(collector);
    for (var stmt in moorRequest.resolvedTask.lastResult.statements) {
      stmt.accept(visitor);
    }
  }
}

class _FoldingVisitor extends RecursiveVisitor<void> {
  final FoldingCollector collector;

  _FoldingVisitor(this.collector);

  @override
  void visitCreateTableStatement(CreateTableStatement e) {
    final startBody = e.openingBracket;
    final endBody = e.closingBracket;

    // report everything between the two brackets as class body
    final first = startBody.span.end.offset + 1;
    final last = endBody.span.start.offset - 1;

    if (last - first < 0) return; // empty body, e.g. CREATE TABLE ()

    collector.addRegion(first, last - first, FoldingKind.CLASS_BODY);
  }
}
