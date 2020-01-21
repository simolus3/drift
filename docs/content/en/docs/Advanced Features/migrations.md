---
title: "Migrations"
weight: 10
description: Define what happens when your database gets created or updated
aliases:
 - /migrations
---

Moor provides a migration API that can be used to gradually apply schema changes after bumping
the `schemaVersion` getter inside the `Database` class. To use it, override the `migration`
getter. Here's an example: Let's say you wanted to add a due date to your todo entries:
```dart
class Todos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 6, max: 10)();
  TextColumn get content => text().named('body')();
  IntColumn get category => integer().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()(); // new, added column
}
```
We can now change the `database` class like this:
```dart
  @override
  int get schemaVersion => 2; // bump because the tables have changed

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) {
      return m.createAllTables();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from == 1) {
        // we added the dueDate property in the change from version 1
        await m.addColumn(todos, todos.dueDate);
      }
    }
  );

  // rest of class can stay the same
```
You can also add individual tables or drop them - see the reference of [Migrator](https://pub.dev/documentation/moor/latest/moor_web/Migrator-class.html)
for all the available options. You can't use the high-level query API in migrations - calling `select` or similar 
methods will throw.

`sqlite` can feel a bit limiting when it comes to migrations - there only are methods to create tables and columns.
Existing columns can't be altered or removed. A workaround is described [here](https://stackoverflow.com/a/805508), it
can be used together with [`issueCustomQuery`](https://pub.dev/documentation/moor/latest/moor/Migrator/issueCustomQuery.html)
to run the statements.

## Post-migration callbacks
Starting from moor 1.5, you can use the `beforeOpen` parameter in the `MigrationStrategy` which will be called after
migrations, but after any other queries are run. You could use it to populate data after the database has been created:
```dart
beforeOpen: (details) async {
    if (details.wasCreated) {
      final workId = await into(categories).insert(Category(description: 'Work'));
    
      await into(todos).insert(TodoEntry(
            content: 'A first todo entry',
            category: null,
            targetDate: DateTime.now(),
      ));
    
      await into(todos).insert(
            TodoEntry(
              content: 'Rework persistence code',
              category: workId,
              targetDate: DateTime.now().add(const Duration(days: 4)),
      ));
    }
},
```
You could also activate pragma statements that you need:
```dart
beforeOpen: (details) async {
  if (details.wasCreated) {
    // ...
  }
  await customStatement('PRAGMA foreign_keys = ON');
}
```

## During development

During development, you might be changing your schema very often and don't want to write migrations for that
yet. You can just delete your apps' data and reinstall the app - the database will be deleted and all tables
will be created again. Please note that uninstalling is not enough sometimes - Android might have backed up
the database file and will re-create it when installing the app again.

You can also delete and re-create all tables everytime your app is opened, see [this comment](https://github.com/simolus3/moor/issues/188#issuecomment-542682912)
on how that can be achieved.