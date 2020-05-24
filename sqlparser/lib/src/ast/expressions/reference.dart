part of '../ast.dart';

/// Expression that refers to an individual expression declared somewhere else
/// in the table.
///
/// For instance, in "SELECT table.c FROM table", the "table.c" is a reference
/// that refers to the column "c" in a table "table". In "SELECT COUNT(*) AS c,
/// 2 * c AS d FROM table", the "c" after the "2 *" is a reference that refers
/// to the expression "COUNT(*)".
class Reference extends Expression with ReferenceOwner {
  final String tableName;
  final String columnName;

  Column get resolvedColumn => resolved as Column;

  Reference({this.tableName, this.columnName});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitReference(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}

  @override
  Iterable<AstNode> get childNodes => const [];

  @override
  bool contentEquals(Reference other) {
    return other.tableName == tableName && other.columnName == columnName;
  }

  @override
  String toString() {
    if (tableName != null) {
      return 'Reference to the column $tableName.$columnName';
    } else {
      return 'Reference to the column $columnName';
    }
  }
}
