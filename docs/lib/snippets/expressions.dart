import 'package:drift/drift.dart';

import 'tables/filename.dart';

extension Expressions on MyDatabase {
  // #docregion emptyCategories
  Future<List<Category>> emptyCategories() {
    final hasNoTodo = notExistsQuery(
        select(todos)..where((row) => row.category.equalsExp(categories.id)));
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
