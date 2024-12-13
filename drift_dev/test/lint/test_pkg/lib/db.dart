import 'package:drift/drift.dart';

part 'db.g.dart';

class Users extends Table {
  late final id = integer().autoIncrement()();
  late final name = text()();
  // expect_lint: drift_build_errors
  late final age = integer();
  // expect_lint: drift_build_errors
  late final group = int64().references(Groups, #id)();
}

class Groups extends Table {
  late final id = integer().autoIncrement()();
  late final name = text()();
}

class BrokenTable extends Table {
  // expect_lint: drift_build_errors
  IntColumn get unknownRef => integer().customConstraint('CHECK foo > 10')();
}

@DriftDatabase(tables: [Users])
class TestDatabase extends _$TestDatabase {
  TestDatabase(super.e);

  @override
  int get schemaVersion => 1;

  a() async {
    transaction(
      () async {
        // expect_lint: unawaited_futures_in_transaction
        into(users).insert(UsersCompanion.insert(name: 'name'));
        await into(users).insert(UsersCompanion.insert(name: 'name'));
      },
    );
    // expect_lint: non_null_insert_with_ignore
    await into(users).insertReturning(UsersCompanion.insert(name: 'name'),
        mode: InsertMode.insertOrIgnore);
    // expect_lint: non_null_insert_with_ignore
    await managers.users
        .createReturning((o) => o(name: "hi"), mode: InsertMode.insertOrIgnore);
    await into(users).insertReturningOrNull(UsersCompanion.insert(name: 'name'),
        mode: InsertMode.insertOrIgnore);
    await managers.users.createReturningOrNull((o) => o(name: "hi"),
        mode: InsertMode.insertOrIgnore);
    await into(users).insertReturning(UsersCompanion.insert(name: 'name'));
    await managers.users.createReturning((o) => o(name: "hi"));
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          // expect_lint: unawaited_futures_in_migration
          m.createTable(users);
        },
      );
}
