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

class UpdateStatement extends CrudStatement implements StatementWithWhere {
  final FailureMode or;
  final TableReference table;
  final List<SetComponent> set;
  @override
  final Expression where;

  UpdateStatement(
      {WithClause withClause,
      this.or,
      @required this.table,
      @required this.set,
      this.where})
      : super._(withClause);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitUpdateStatement(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [
        if (withClause != null) withClause,
        table,
        ...set,
        if (where != null) where,
      ];

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
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitSetComponent(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [column, expression];

  @override
  bool contentEquals(SetComponent other) => true;
}
