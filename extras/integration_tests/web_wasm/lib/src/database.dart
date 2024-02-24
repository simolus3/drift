import 'package:drift/drift.dart';

part 'database.g.dart';

class TestTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text()();
}

@DriftDatabase(tables: [TestTable])
class TestDatabase extends _$TestDatabase {
  TestDatabase(super.e);

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          await into(testTable).insert(
              TestTableCompanion.insert(content: 'from onUpgrade migration'));
        },
      );

  @override
  int schemaVersion = 1;
}
