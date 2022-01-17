import '../../analysis/analysis.dart';
import '../ast.dart'
    show StarResultColumn, ResultColumn, Renamable, SelectStatement;
import '../node.dart';
import '../visitor.dart';
import 'moor_file.dart';

/// A nested query column, denoted by `LIST(...)` in user queries.
///
/// Nested query columns take a select query and execute it for every result
/// returned from the main query. Nested query columns can only be added to a
/// top level select query, because the result of them can only be computed
/// in dart.
class NestedQueryColumn extends ResultColumn
    implements MoorSpecificNode, Renamable, Referencable {
  @override
  final String? as;

  SelectStatement select;

  NestedQueryColumn({required this.select, this.as});

  @override
  Iterable<AstNode> get childNodes => [select];

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    select = transformer.transformChild(select, this, arg);
  }

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitMoorSpecificNode(this, arg);
  }

  // idk is this required?
  @override
  bool get visibleToChildren => false;
}
