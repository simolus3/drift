---
title: "Migrations"
description: >
  Define what happens when your database gets created or updated
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
You can also add individual tables or drop them - see the reference of [Migrator](https://pub.dev/documentation/moor/latest/moor/Migrator-class.html)
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
beforeOpen: (db, details) async {
    if (details.wasCreated) {
      final workId = await db.into(categories).insert(Category(description: 'Work'));
    
      await db.into(todos).insert(TodoEntry(
            content: 'A first todo entry',
            category: null,
            targetDate: DateTime.now(),
      ));
    
      await db.into(todos).insert(
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
beforeOpen: (db, details) async {
  if (details.wasCreated) {
    // ...
  }
  await db.customStatement('PRAGMA foreign_keys = ON');
}
```
It is important that you run these queries on `db` explicitly. Failing to do so causes a deadlock which prevents the
database from being opened.