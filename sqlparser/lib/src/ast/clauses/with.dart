part of '../ast.dart';

class WithClause extends AstNode {
  Token? withToken;

  final bool recursive;
  Token? recursiveToken;

  List<CommonTableExpression> ctes;

  WithClause({required this.recursive, required this.ctes});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitWithClause(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    ctes = transformer.transformChildren(ctes, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => ctes;
}

enum MaterializationHint {
  materialized,
  notMaterialized,
}

class CommonTableExpression extends AstNode with ResultSet {
  final String cteTableName;

  final MaterializationHint? materializationHint;

  /// The `not` token before the `materialized` token, if there is any.
  Token? not;

  /// The `materialized` token, if there is any.
  Token? materialized;

  /// If this common table expression has explicit column names, e.g. with
  /// `cnt(x) AS (...)`, contains the column names (`['x']`, in that case).
  /// Otherwise null.
  final List<String>? columnNames;
  BaseSelectStatement as;

  Token? asToken;
  IdentifierToken? tableNameToken;

  @override
  List<Column>? resolvedColumns;

  CommonTableExpression({
    required this.cteTableName,
    this.materializationHint,
    this.columnNames,
    required this.as,
  });

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitCommonTableExpression(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    as = transformer.transformChild(as, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [as];

  @override
  bool get visibleToChildren => true;
}
