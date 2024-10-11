import 'package:drift/drift.dart';

part 'db.g.dart';

class Users extends Table {
  late final id = integer().autoIncrement()();
  late final name = text()();
  // expect_lint: drift_build_errors
  late final age = integer();
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
      },
    );
  }
}
