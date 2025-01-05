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

  void queries() {
    // #docregion date1
    select(users).where((u) => u.birthDate.year.isSmallerThanValue(1950));
    // #enddocregion date1
  }

  // #docregion date2
  Future<void> increaseDueDates() async {
    final change = TodoItemsCompanion.custom(
        dueDate: todoItems.dueDate + Duration(days: 1));
    await update(todoItems).write(change);
  }
  // #enddocregion date2

  // #docregion date3
  Future<void> moveDueDateToNextMonday() async {
    final change = TodoItemsCompanion.custom(
        dueDate: todoItems.dueDate
            .modify(DateTimeModifier.weekday(DateTime.monday)));
    await update(todoItems).write(change);
  }
  // #enddocregion date3
}

// #docregion bitwise
Expression<int> bitwiseMagic(Expression<int> a, Expression<int> b) {
  // Generates `~(a & b)` in SQL.
  return ~(a.bitwiseAnd(b));
}
// #enddocregion bitwise
