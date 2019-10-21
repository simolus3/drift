part of '../ast.dart';

class WithClause extends AstNode {
  Token withToken;

  final bool recursive;
  Token recursiveToken;

  final List<CommonTableExpression> ctes;

  WithClause({@required this.recursive, @required this.ctes});

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitWithClause(this);

  @override
  Iterable<AstNode> get childNodes => ctes;

  @override
  bool contentEquals(WithClause other) => other.recursive == recursive;
}

class CommonTableExpression extends AstNode {
  final String cteTableName;

  /// If this common table expression has explicit column names, e.g. with
  /// `cnt(x) AS (...)`, contains the column names (`['x']`, in that case).
  /// Otherwise null.
  final List<String> columnNames;
  final BaseSelectStatement as;

  Token asToken;
  IdentifierToken tableNameToken;

  CommonTableExpression(
      {@required this.cteTableName, this.columnNames, @required this.as});

  @override
  T accept<T>(AstVisitor<T> visitor) {
    return visitor.visitCommonTableExpression(this);
  }

  @override
  Iterable<AstNode> get childNodes => [as];

  @override
  bool contentEquals(CommonTableExpression other) {
    return other.cteTableName == cteTableName;
  }
}
