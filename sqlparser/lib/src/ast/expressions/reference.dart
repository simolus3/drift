part of '../ast.dart';

/// Expression that refers to an individual column.
class Reference extends Expression {
  final String tableName;
  final String columnName;

  Reference({this.tableName, this.columnName});

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitReference(this);

  @override
  Iterable<AstNode> get childNodes => const [];

  @override
  bool contentEquals(Reference other) {
    return other.tableName == tableName && other.columnName == columnName;
  }
}
