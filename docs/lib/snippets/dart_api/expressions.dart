import 'package:drift/drift.dart';

import '../_shared/todo_tables.dart';
import '../_shared/todo_tables.drift.dart';

extension Snippets on CanUseCommonTables {
  // #docregion emptyCategories
  Future<List<Category>> emptyCategories() {
    final hasNoTodo = notExistsQuery(select(todoItems)
      ..where((row) => row.category.equalsExp(categories.id)));
    return (select(categories)..where((row) => hasNoTodo)).get();
  }
  // #enddocregion emptyCategories
}

// #docregion bitwise
Expression<int> bitwiseMagic(Expression<int> a, Expression<int> b) {
  // Generates `~(a & b)` in SQL.
  return ~(a.bitwiseAnd(b));
}
// #enddocregion bitwise
