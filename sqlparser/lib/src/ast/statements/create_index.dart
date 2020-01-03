part of '../ast.dart';

class CreateIndexStatement extends Statement
    implements CreatingStatement, HasWhereClause {
  final String indexName;
  final bool unique;
  final bool ifNotExists;
  IdentifierToken nameToken;

  final TableReference on;
  final List<IndexedColumn> columns;
  @override
  final Expression where;

  CreateIndexStatement(
      {@required this.indexName,
      this.unique = false,
      this.ifNotExists = false,
      @required this.on,
      @required this.columns,
      this.where});

  @override
  String get createdName => indexName;

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitCreateIndexStatement(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes =>
      [on, ...columns, if (where != null) where];

  @override
  bool contentEquals(CreateIndexStatement other) {
    return other.indexName == indexName;
  }
}

/// Note that this class matches the productions listed at https://www.sqlite.org/syntax/indexed-column.html
/// We don't have a special case for `column-name` (those are [Reference]s).
/// The `COLLATE` branch is covered by parsing a [CollateExpression] for
/// [expression].
class IndexedColumn extends AstNode {
  /// The expression on which the index should be created. Most commonly a
  /// [Reference], for simple column names.
  final Expression expression;
  // nullable
  final OrderingMode ordering;

  IndexedColumn(this.expression, [this.ordering]);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitIndexedColumn(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [expression];

  @override
  bool contentEquals(IndexedColumn other) => other.ordering == ordering;
}
