part of '../ast.dart';

class DeleteStatement extends Statement
    with CrudStatement
    implements HasWhereClause {
  final TableReference from;
  @override
  final Expression where;

  DeleteStatement({@required this.from, this.where});

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitDeleteStatement(this);

  @override
  Iterable<AstNode> get childNodes => [from, if (where != null) where];

  @override
  bool contentEquals(DeleteStatement other) => true;
}
