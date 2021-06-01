import '../../reader/tokenizer/token.dart';
import '../ast.dart'; // todo: Remove this import
import '../node.dart';
import '../visitor.dart';
import 'statement.dart';

class CreateIndexStatement extends Statement
    implements CreatingStatement, StatementWithWhere {
  final String indexName;
  final bool unique;
  final bool ifNotExists;
  IdentifierToken? nameToken;

  TableReference on;
  List<IndexedColumn> columns;
  @override
  Expression? where;

  CreateIndexStatement(
      {required this.indexName,
      this.unique = false,
      this.ifNotExists = false,
      required this.on,
      required this.columns,
      this.where});

  @override
  String get createdName => indexName;

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitCreateIndexStatement(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    on = transformer.transformChild(on, this, arg);
    columns = transformer.transformChildren(columns, this, arg);
    where = transformer.transformNullableChild(where, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes =>
      [on, ...columns, if (where != null) where!];
}

/// Note that this class matches the productions listed at https://www.sqlite.org/syntax/indexed-column.html
/// We don't have a special case for `column-name` (those are [Reference]s).
/// The `COLLATE` branch is covered by parsing a [CollateExpression] for
/// [expression].
class IndexedColumn extends AstNode {
  /// The expression on which the index should be created. Most commonly a
  /// [Reference], for simple column names.
  Expression expression;
  final OrderingMode? ordering;

  IndexedColumn(this.expression, [this.ordering]);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitIndexedColumn(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [expression];

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    expression = transformer.transformChild(expression, this, arg);
  }
}
