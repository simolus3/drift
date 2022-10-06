import 'package:drift/drift.dart';

import 'filename.dart';

// #docregion unique
class WithUniqueConstraints extends Table {
  IntColumn get a => integer().unique()();

  IntColumn get b => integer()();
  IntColumn get c => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {b, c}
      ];

  // Effectively, this table has two unique key sets: (a) and (b, c).
}
// #enddocregion unique

// #docregion view
abstract class CategoryTodoCount extends View {
  // Getters define the tables that this view is reading from.
  Todos get todos;
  Categories get categories;

  // Custom expressions can be given a name by defining them as a getter:.
  Expression<int> get itemCount => todos.id.count();

  @override
  Query as() =>
      // Views can select columns defined as expression getters on the class, or
      // they can reference columns from other tables.
      select([categories.description, itemCount])
          .from(categories)
          .join([innerJoin(todos, todos.category.equalsExp(categories.id))]);
}
// #enddocregion view
