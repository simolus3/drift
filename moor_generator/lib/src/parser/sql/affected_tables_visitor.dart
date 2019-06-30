import 'package:sqlparser/sqlparser.dart';

/// An AST-visitor that walks sql statements and finds all tables referenced in
/// them.
class AffectedTablesVisitor extends RecursiveVisitor<void> {
  final Set<Table> foundTables = {};

  @override
  void visitReference(Reference e) {
    final column = e.resolved;
    if (column is TableColumn) {
      foundTables.add(column.table);
    }

    visitChildren(e);
  }

  @override
  void visitQueryable(Queryable e) {
    if (e is TableReference) {
      final table = e.resolved as Table;
      if (table != null) {
        foundTables.add(table);
      }
    }

    visitChildren(e);
  }
}
