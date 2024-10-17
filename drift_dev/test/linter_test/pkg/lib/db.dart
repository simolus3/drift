import 'package:drift/drift.dart';

part 'db.g.dart';

class Users extends Table {
  late final id = integer().autoIncrement()();
  late final name = text()();
  // expect_lint: drift_build_errors
  late final age = integer();
  // ignore: drift_build_errors
  late final age2 = integer()();
  // expect_lint: drift_build_errors
  late final group = integer().references(Group, #id)();
  // expect_lint: drift_build_errors
  late final group2 = integer().references(Group, #id)();
}

extension type PK(String id) {}

class Group extends Table {
  late final id = text() //
      .map(TypeConverter.extensionType<PK, String>())();
  late final id2 = integer() //
      .map(TypeConverter.extensionType<PK, int>())();
}

class BrokenTable extends Table {
  // expect_lint: drift_build_errors
  IntColumn get unknownRef => integer().customConstraint('CHECK foo > 10')();
}

@DriftDatabase(tables: [Users, Group])
class TestDatabase extends _$TestDatabase {
  TestDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          // expect_lint: unawaited_futures_in_migration
          m.addColumn(users, users.name);
        },
      );

  a() async {
    // expect_lint: offset_without_limit
    managers.users.get(offset: 1);
    // expect_lint: offset_without_limit
    managers.users.watch(offset: 1);
    managers.users.get();
    managers.users.get(distinct: true);
    managers.users.get(limit: 1);
    managers.users.get(limit: 1, distinct: true);
    managers.users.get(limit: 1, offset: 1);
    managers.users.get(limit: 1, offset: 1, distinct: true);

    transaction(
      () async {
        // expect_lint: unawaited_futures_in_transaction
        into(users)
            .insert(UsersCompanion.insert(name: 'name', age2: 1, group: 5));
      },
    );
  }
}

class A {
  void get() {}
}

void a() {
  A().get();
}
