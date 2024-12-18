import 'package:drift/drift.dart';

import '../setup/database.dart';

extension CoreApi on AppDatabase {
  // #docregion core
  Selectable<TodoItem> allItemsAfter(DateTime min) {
    return select(todoItems)
      ..where((row) => row.createdAt.isBiggerThanValue(min));
  }
  // #enddocregion core

  // #docregion tableUpdates
  Future<void> listenForUpdates() async {
    final stream = tableUpdates(TableUpdateQuery.onTable(
      todoItems,
      limitUpdateKind: UpdateKind.update,
    ));

    await for (final event in stream) {
      print('Update on todos table: $event');
    }
  }
  // #enddocregion tableUpdates

  // #docregion markUpdated
  void markUpdated() {
    notifyUpdates({TableUpdate.onTable(todoItems, kind: UpdateKind.insert)});
  }
  // #enddocregion markUpdated
}

extension Manager on AppDatabase {
  // #docregion manager
  Selectable<TodoItem> allItemsAfter(DateTime min) {
    return managers.todoItems.filter((c) => c.createdAt.isAfter(min));
  }
  // #enddocregion manager
}

extension CustomQueries on AppDatabase {
  // #docregion custom
  Selectable<TodoItem> allItemsAfter(DateTime min) {
    return customSelect(
      'SELECT * FROM todo_items WHERE created_at > ?',
      variables: [Variable.withDateTime(min)],
      readsFrom: {todoItems}, // (1)!
    ).map((row) => todoItems.map(row.data));
  }
  // #enddocregion custom
}
