import '../../analysis/analysis.dart';
import '../ast.dart' show StarResultColumn, ResultColumn, Renamable;
import '../node.dart';
import '../visitor.dart';
import 'drift_file.dart';

/// A nested star result column, denoted by `**` in user queries.
///
/// Nested star result columns behave similar to a regular [StarResultColumn]
/// when the query is actually run. However, they will affect generated code
/// when using drift.
class NestedStarResultColumn extends ResultColumn
    implements DriftSpecificNode, Renamable {
  final String tableName;
  ResultSet? resultSet;

  @override
  final String? as;

  NestedStarResultColumn({required this.tableName, this.as});

  @override
  Iterable<AstNode> get childNodes => const [];

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitDriftSpecificNode(this, arg);
  }
}
