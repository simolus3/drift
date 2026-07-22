// Example on how to test your application's database code.
import 'package:app_drift3/database/database.dart';
import 'package:drift3/drift.dart';
import 'package:drift_sqlite/drift_sqlite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    final inMemory = DriftConnection(
      dialect: SqliteDialect.new,
      openConnection: () async => SqliteConnection(
        sqlite3.openInMemory(),
      ),
    );
    database = AppDatabase(inMemory);
  });

  tearDown(() => database.close());

  test('can search for todo entries', () async {
    final entry = await database.todoEntries
        .statements(database)
        .insertReturning(
            TodoEntriesCompanion.insert(description: 'test todo entry'));

    final result = await database.search('test');
    expect(result.map((e) => e.entry), contains(entry));
  });
}
