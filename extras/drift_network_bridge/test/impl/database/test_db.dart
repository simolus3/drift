// For more information on using drift, please see https://drift.simonbinder.eu/docs/getting-started/
// A full cross-platform example is available here: https://github.com/simolus3/drift/tree/develop/examples/app

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'test_db.g.dart';

@DataClassName('TodoCategory')
class TodoCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

class TodoItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get content => text().nullable()();
  IntColumn get categoryId => integer().references(TodoCategories, #id)();

  TextColumn get generatedText => text().nullable().generatedAs(
      title + const Constant(' (') + content + const Constant(')'))();
}

abstract class TodoCategoryItemCount extends View {
  TodoItems get todoItems;
  TodoCategories get todoCategories;

  Expression<int> get itemCount => todoItems.id.count();

  @override
  Query as() => select([
    todoCategories.name,
    itemCount,
  ]).from(todoCategories).join([
    innerJoin(todoItems, todoItems.categoryId.equalsExp(todoCategories.id))
  ]);
}

@DriftView(name: 'customViewName')
abstract class TodoItemWithCategoryNameView extends View {
  TodoItems get todoItems;
  TodoCategories get todoCategories;

  Expression<String> get title =>
      todoItems.title +
          const Constant('(') +
          todoCategories.name +
          const Constant(')');

  @override
  Query as() => select([todoItems.id, title]).from(todoItems).join([
    innerJoin(
        todoCategories, todoCategories.id.equalsExp(todoItems.categoryId))
  ]);
}

@DriftDatabase(tables: [
  TodoItems,
  TodoCategories,
], views: [
  TodoCategoryItemCount,
  TodoItemWithCategoryNameView,
])
class TestDatabase extends _$Database {
  TestDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();

        // Add a bunch of default items in a batch
        await batch((b) {
          b.insertAll(todoItems, [
            TodoItemsCompanion.insert(title: 'A first entry', categoryId: 0),
            TodoItemsCompanion.insert(
              title: 'Todo: Checkout drift',
              content: const Value('Drift is a persistence library for Dart '
                  'and Flutter applications.'),
              categoryId: 0,
            ),
          ]);
        });
      },
    );
  }
  Stream<List<TodoItem>> get allItems => select(todoItems).watch();
}

