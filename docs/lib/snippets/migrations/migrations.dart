import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_docs/snippets/setup/database.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'migrations.g.dart';

const kDebugMode = false;

// #docregion table
@TableIndex(name: "todos__title", columns: {#title})
class Todos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 6, max: 10)();
  TextColumn get content => text().named('body')();
  IntColumn get category => integer().nullable()();
  DateTimeColumn get dueDate =>
      dateTime().nullable()(); // new, added column in v2
  IntColumn get priority => integer().nullable()(); // new, added column in v3
}
// #enddocregion table

@DriftDatabase(tables: [Todos])
class MyDatabase extends _$MyDatabase {
  MyDatabase(super.e);

  // #docregion start
  // ...
  // #docregion schemaVersion
  @override
  int get schemaVersion => 3; // bump when changing schema
  // #enddocregion schemaVersion
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      // #docregion beforeOpen
      beforeOpen: (details) async {
        // Run PRAGMA statements
        await customStatement('PRAGMA foreign_keys = ON');

        // Create an initial todo if we just created the database+
        if (details.wasCreated) {
          await managers.todos.create((o) =>
              o(title: "Your First Todo", content: "Enter your content here"));
        }
      },
      // #enddocregion beforeOpen
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      // #docregion manualOnUpgrade
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // we added the dueDate property in the change from version 1 to
          // version 2
          await m.addColumn(todos, todos.dueDate);
        }
        if (from < 3) {
          // we added the priority property in the change from version 1 or 2
          // to version 3
          await m.addColumn(todos, todos.priority);
        }
      },
      // #enddocregion manualOnUpgrade
    );
  }
  // The rest of the class can stay the same
  // #enddocregion start

  MigrationStrategy get withForeignKeyCheck {
    // #docregion structured
    return MigrationStrategy(
      onUpgrade: (m, from, to) async {
        // disable foreign_keys before migrations
        await customStatement('PRAGMA foreign_keys = OFF');

        await transaction(() async {
          // put your migration logic here
        });

        // Assert that the schema is valid after migrations
        if (kDebugMode) {
          final wrongForeignKeys =
              await customSelect('PRAGMA foreign_key_check').get();
          assert(wrongForeignKeys.isEmpty,
              '${wrongForeignKeys.map((e) => e.data)}');
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
        // ....
      },
    );
    // #enddocregion structured
  }

  MigrationStrategy get changeType {
    const yourOldVersion = 4;
    // #docregion change_type
    return MigrationStrategy(
      onUpgrade: (m, old, to) async {
        if (old <= yourOldVersion) {
          await m.alterTable(
            TableMigration(todos, columnTransformer: {
              todos.category: todos.category.cast<int>(),
            }),
          );
        }
      },
    );
    // #enddocregion change_type
  }
}
