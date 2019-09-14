part of '../ast.dart';

enum FailureMode {
  rollback,
  abort,
  replace,
  fail,
  ignore,
}

const Map<TokenType, FailureMode> _tokensToMode = {
  TokenType.rollback: FailureMode.rollback,
  TokenType.abort: FailureMode.abort,
  TokenType.replace: FailureMode.replace,
  TokenType.fail: FailureMode.fail,
  TokenType.ignore: FailureMode.ignore,
};

class UpdateStatement extends Statement
    with CrudStatement
    implements HasWhereClause {
  final FailureMode or;
  final TableReference table;
  final List<SetComponent> set;
  @override
  final Expression where;

  UpdateStatement(
      {this.or, @required this.table, @required this.set, this.where});

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitUpdateStatement(this);

  @override
  Iterable<AstNode> get childNodes => [table, ...set, if (where != null) where];

  @override
  bool contentEquals(UpdateStatement other) {
    return other.or == or;
  }

  static FailureMode failureModeFromToken(TokenType token) {
    return _tokensToMode[token];
  }
}

class SetComponent extends AstNode {
  final Reference column;
  final Expression expression;

  SetComponent({@required this.column, @required this.expression});

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitSetComponent(this);

  @override
  Iterable<AstNode> get childNodes => [column, expression];

  @override
  bool contentEquals(SetComponent other) => true;
}
