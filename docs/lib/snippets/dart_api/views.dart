import 'package:drift/drift.dart';

class Todos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 6, max: 32)();
  TextColumn get content => text().named('body')();
  IntColumn get category => integer().nullable()();
}

@DataClassName('Category')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get description => text()();
}

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
