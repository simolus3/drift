part of '../ast.dart';

/// Expression that refers to an individual expression declared somewhere else
/// in the table.
///
/// For instance, in "SELECT table.c FROM table", the "table.c" is a reference
/// that refers to the column "c" in a table "table". In "SELECT COUNT(*) AS c,
/// 2 * c AS d FROM table", the "c" after the "2 *" is a reference that refers
/// to the expression "COUNT(*)".
class Reference extends Expression with ReferenceOwner {
  /// Entity can be either a table or a view.
  final String? entityName;
  final String columnName;

  Column? get resolvedColumn => resolved as Column?;

  Reference({this.entityName, required this.columnName});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitReference(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}

  @override
  Iterable<AstNode> get childNodes => const [];

  @override
  String toString() {
    if (entityName != null) {
      return 'Reference to the column $entityName.$columnName';
    } else {
      return 'Reference to the column $columnName';
    }
  }
}
