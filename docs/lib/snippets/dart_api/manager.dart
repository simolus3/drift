import 'package:drift/drift.dart';

import '../setup/database.dart';

extension ManagerExamples on AppDatabase {
  // #docregion manager_create
  Future<void> createTodoItem() async {
    // Create a new item
    await managers.todoItems
        .create((o) => o(title: 'Title', content: 'Content'));

    // We can also use `mode` and `onConflict` parameters, just
    // like in the `[InsertStatement.insert]` method on the table
    await managers.todoItems.create(
        (o) => o(title: 'Title', content: 'New Content'),
        mode: InsertMode.replace);

    // We can also create multiple items at once
    await managers.todoItems.bulkCreate(
      (o) => [
        o(title: 'Title 1', content: 'Content 1'),
        o(title: 'Title 2', content: 'Content 2'),
      ],
    );
  }
  // #enddocregion manager_create

  // #docregion manager_update
  Future<void> updateTodoItems() async {
    // Update all items
    await managers.todoItems.update((o) => o(content: Value('New Content')));

    // Update multiple items
    await managers.todoItems
        .filter((f) => f.id.isIn([1, 2, 3]))
        .update((o) => o(content: Value('New Content')));
  }
  // #docregion manager_update

  // #docregion manager_replace
  Future<void> replaceTodoItems() async {
    // Replace a single item
    var obj = await managers.todoItems.filter((o) => o.id(1)).getSingle();
    obj = obj.copyWith(content: 'New Content');
    await managers.todoItems.replace(obj);

    // Replace multiple items
    var objs =
        await managers.todoItems.filter((o) => o.id.isIn([1, 2, 3])).get();
    objs = objs.map((o) => o.copyWith(content: 'New Content')).toList();
    await managers.todoItems.bulkReplace(objs);
  }
  // #docregion manager_replace

  // #docregion manager_delete
  Future<void> deleteTodoItems() async {
    // Delete all items
    await managers.todoItems.delete();

    // Delete a single item
    await managers.todoItems.filter((f) => f.id(5)).delete();
  }
  // #docregion manager_delete
}
