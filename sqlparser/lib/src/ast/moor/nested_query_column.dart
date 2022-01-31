import '../ast.dart' show ResultColumn, Renamable, SelectStatement;
import '../node.dart';
import '../visitor.dart';
import 'moor_file.dart';

/// To wrap the query name into its own type, to avoid conflicts when using
/// the [AstNode] metadata.
class _NestedColumnNameMetadata {
  final String? name;

  _NestedColumnNameMetadata(this.name);
}

/// A nested query column, denoted by `LIST(...)` in user queries.
///
/// Nested query columns take a select query and execute it for every result
/// returned from the main query. Nested query columns can only be added to a
/// top level select query, because the result of them can only be computed
/// in dart.
class NestedQueryColumn extends ResultColumn
    implements MoorSpecificNode, Renamable {
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

  /// The unique name for this query. Used to identify it and it's variables in
  /// the AST tree.
  set queryName(String? name) => setMeta(_NestedColumnNameMetadata(name));

  String? get queryName => meta<_NestedColumnNameMetadata>()?.name;
}
