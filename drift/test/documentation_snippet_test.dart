import 'package:drift/drift.dart';
import 'package:drift_docs/snippets/migrations/datetime_conversion.dart';
import 'package:test/test.dart';

import 'generated/custom_tables.dart';
import 'generated/todos.dart';
import 'test_utils/test_utils.dart';

/// Test for some snippets embedded on https://drift.simonbinder.eu to make sure
/// that they are still up to date and work as intended with the latest drift
/// version.
void main() {
  group('changing datetime format', () {
    test('unix timestamp to text', () async {
      // Note: CustomTablesDb has been compiled to use datetimes as text by
      // default.
      final db = CustomTablesDb.connect(testInMemoryDatabase());
      addTearDown(db.close);

      final time = DateTime.fromMillisecondsSinceEpoch(
        1000 * (DateTime.now().millisecondsSinceEpoch ~/ 1000),
        isUtc: true,
      );

      // Re-create the `mytable` table (the only one using dates) to use unix
      // timestamps
      await db.customStatement('DROP TABLE mytable');
      await db.customStatement('''
CREATE TABLE mytable (
    someid INTEGER NOT NULL,
    sometext TEXT,
    is_inserting BOOLEAN,
    somedate INTEGER,
    PRIMARY KEY (someid DESC)
);
''');

      await db.customStatement('''
INSERT INTO mytable (someid) VALUES (1); -- nullable value
INSERT INTO mytable (someid, somedate) VALUES (2, ${time.millisecondsSinceEpoch ~/ 1000});
''');

      // Run conversion from unix timestamps to text
      await db.migrateFromUnixTimestampsToText(db.createMigrator());

      // Check that the values are still there!
      final rows = await (db.select(db.mytable)
            ..orderBy([(row) => OrderingTerm.asc(row.someid)]))
          .get();

      expect(rows, [
        const MytableData(someid: 1),
        MytableData(someid: 2, somedate: time),
      ]);
    });

    test('text to unix timestamp', () async {
      // First, create all tables using text as datetime
      final db = TodoDb.connect(testInMemoryDatabase());
      db.options = const DriftDatabaseOptions(storeDateTimeAsText: true);
      addTearDown(db.close);

      final time = DateTime.fromMillisecondsSinceEpoch(
          1000 * (DateTime.now().millisecondsSinceEpoch ~/ 1000));

      await db.into(db.users).insert(
            UsersCompanion.insert(
              name: 'Some user',
              profilePicture: Uint8List(0),
              creationTime: Value(time),
            ),
          );

      await db.into(db.todosTable).insert(TodosTableCompanion.insert(
            content: 'with null date',
          ));
      await db.into(db.todosTable).insert(TodosTableCompanion.insert(
            content: 'with due date',
            targetDate: Value(time),
          ));

      // Next, migrate back to unix timestamps
      db.options = const DriftDatabaseOptions(storeDateTimeAsText: false);
      final migrator = db.createMigrator();
      await migrator.drop(db.categoryTodoCountView);
      await migrator.drop(db.todoWithCategoryView);
      await db.migrateFromTextDateTimesToUnixTimestamps(migrator);
      await migrator.create(db.categoryTodoCountView);
      await migrator.create(db.todoWithCategoryView);

      expect(await db.users.select().getSingle(),
          isA<User>().having((e) => e.creationTime, 'creationTime', time));

      expect(await db.todosTable.select().get(), [
        const TodoEntry(id: 1, content: 'with null date'),
        TodoEntry(id: 2, content: 'with due date', targetDate: time),
      ]);
    });

    test('text to unix timestamp, support old sqlite', () async {
      // First, create all tables using text as datetime
      final db = TodoDb.connect(testInMemoryDatabase());
      db.options = const DriftDatabaseOptions(storeDateTimeAsText: true);
      addTearDown(db.close);

      final time = DateTime.fromMillisecondsSinceEpoch(
          1000 * (DateTime.now().millisecondsSinceEpoch ~/ 1000));

      await db.into(db.users).insert(
            UsersCompanion.insert(
              name: 'Some user',
              profilePicture: Uint8List(0),
              creationTime: Value(time),
            ),
          );

      await db.into(db.todosTable).insert(TodosTableCompanion.insert(
            content: 'with null date',
          ));
      await db.into(db.todosTable).insert(TodosTableCompanion.insert(
            content: 'with due date',
            targetDate: Value(time),
          ));

      // Next, migrate back to unix timestamps
      db.options = const DriftDatabaseOptions(storeDateTimeAsText: false);
      final migrator = db.createMigrator();
      await migrator.drop(db.categoryTodoCountView);
      await migrator.drop(db.todoWithCategoryView);
      await db.migrateFromTextDateTimesToUnixTimestampsPre338(migrator);
      await migrator.create(db.categoryTodoCountView);
      await migrator.create(db.todoWithCategoryView);

      expect(await db.users.select().getSingle(),
          isA<User>().having((e) => e.creationTime, 'creationTime', time));

      expect(await db.todosTable.select().get(), [
        const TodoEntry(id: 1, content: 'with null date'),
        TodoEntry(id: 2, content: 'with due date', targetDate: time),
      ]);
    });
  });
}
