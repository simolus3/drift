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
