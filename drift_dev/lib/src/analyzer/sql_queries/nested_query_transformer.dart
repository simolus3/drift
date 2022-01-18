import 'package:sqlparser/sqlparser.dart';

/// Generates additional rows in the select statement for the nested queries
class NestedQueryTransformer extends Transformer<void> {
  AstNode rewrite(AstNode node) {
    return transform(node, null)!;
  }

  @override
  AstNode? visitSelectStatement(SelectStatement e, void arg) {
    final collector = _NestedQueryVariableCollector();
    e.accept(collector, null);

    for (final result in collector.results) {
      e.columns.add(
        ExpressionResultColumn(
          expression: Reference(
            entityName: result.variable.entityName,
            columnName: result.variable.columnName,
          ),
          as: '${result.prefix}_${result.variable.name}',
        ),
      );
    }

    // Only top level select statements support nested queries
    return e;
  }
}

class _NestedQueryVariableCollector extends RecursiveVisitor<String?, void> {
  final List<_VariableWithPrefix> results;

  _NestedQueryVariableCollector() : results = [];

  @override
  void visitMoorSpecificNode(MoorSpecificNode e, String? arg) {
    if (e is NestedQueryColumn) {
      super.visitMoorSpecificNode(e, e.queryName);
    } else {
      super.visitMoorSpecificNode(e, arg);
    }
  }

  @override
  void visitNestedQueryVariable(NestedQueryVariable e, String? arg) {
    assert(arg != null, 'the query name should not be null here');

    results.add(_VariableWithPrefix(arg!, e));

    super.visitNestedQueryVariable(e, arg);
  }
}

class _VariableWithPrefix {
  final String prefix;
  final NestedQueryVariable variable;

  _VariableWithPrefix(this.prefix, this.variable);
}
