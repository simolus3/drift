part of '../ast.dart';

class DeleteStatement extends Statement {
  final TableReference from;
  final Expression where;

  DeleteStatement({@required this.from, this.where});

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitDeleteStatement(this);

  @override
  Iterable<AstNode> get childNodes => [from, if (where != null) where];

  @override
  bool contentEquals(DeleteStatement other) => true;
}
