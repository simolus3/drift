import '../../analysis/analysis.dart';
import '../ast.dart' show StarResultColumn, ResultColumn;
import '../node.dart';
import '../visitor.dart';

/// A nested star result column, denoted by `**` in user queries.
///
/// Nested star result columns behave similar to a regular [StarResultColumn]
/// when the query is actually run. However, they will affect generated code
/// when using moor.
class NestedStarResultColumn extends ResultColumn {
  final String tableName;
  ResultSet? resultSet;

  NestedStarResultColumn(this.tableName);

  @override
  Iterable<AstNode> get childNodes => const [];

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitMoorNestedStarResultColumn(this, arg);
  }
}
