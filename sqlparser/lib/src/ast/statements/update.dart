import '../../analysis/analysis.dart';
import '../../reader/tokenizer/token.dart';
import '../ast.dart'; // todo: Remove this import

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

class UpdateStatement extends CrudStatement
    implements
        StatementWithWhere,
        HasPrimarySource,
        HasFrom,
        StatementReturningColumns {
  final FailureMode? or;
  @override
  TableReference table;
  List<SetComponent> set;
  @override
  Queryable? from;
  @override
  Expression? where;

  @override
  Returning? returning;
  @override
  ResultSet? returnedResultSet;

  UpdateStatement({
    WithClause? withClause,
    this.or,
    required this.table,
    required this.set,
    this.from,
    this.where,
    this.returning,
  }) : super(withClause);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitUpdateStatement(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    withClause = transformer.transformNullableChild(withClause, this, arg);
    table = transformer.transformChild(table, this, arg);
    set = transformer.transformChildren(set, this, arg);
    from = transformer.transformNullableChild(from, this, arg);
    where = transformer.transformChild(where!, this, arg);
    returning = transformer.transformNullableChild(returning, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [
        if (withClause != null) withClause!,
        table,
        ...set,
        if (from != null) from!,
        if (where != null) where!,
        if (returning != null) returning!,
      ];

  static FailureMode? failureModeFromToken(TokenType token) {
    return _tokensToMode[token];
  }
}

class SetComponent extends AstNode {
  Reference column;
  Expression expression;

  SetComponent({required this.column, required this.expression});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitSetComponent(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    column = transformer.transformChild(column, this, arg);
    expression = transformer.transformChild(expression, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [column, expression];
}
