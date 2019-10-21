part of '../ast.dart';

class DeleteStatement extends CrudStatement implements HasWhereClause {
  final TableReference from;
  @override
  final Expression where;

  DeleteStatement({WithClause withClause, @required this.from, this.where})
      : super._(withClause);

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitDeleteStatement(this);

  @override
  Iterable<AstNode> get childNodes => [
        if (withClause != null) withClause,
        from,
        if (where != null) where,
      ];

  @override
  bool contentEquals(DeleteStatement other) => true;
}
