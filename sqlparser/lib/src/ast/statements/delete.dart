part of '../ast.dart';

class DeleteStatement extends CrudStatement
    implements StatementWithWhere, HasPrimarySource {
  TableReference from;
  @override
  Expression where;

  @override
  TableReference get table => from;

  DeleteStatement({WithClause withClause, @required this.from, this.where})
      : super._(withClause);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitDeleteStatement(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    withClause = transformer.transformNullableChild(withClause, this, arg);
    from = transformer.transformChild(from, this, arg);
    where = transformer.transformNullableChild(where, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [
        if (withClause != null) withClause,
        from,
        if (where != null) where,
      ];

  @override
  bool contentEquals(DeleteStatement other) => true;
}
