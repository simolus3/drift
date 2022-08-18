// Example on how to test your application's database code.
import 'package:app/database/database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    final inMemory = DatabaseConnection(NativeDatabase.memory());
    database = AppDatabase.forTesting(inMemory);
  });

  tearDown(() => database.close());

  test('can search for todo entries', () async {
    final entry = await database.todoEntries.insertReturning(
        TodoEntriesCompanion.insert(description: 'test todo entry'));

    final result = await database.search('test');
    expect(result.map((e) => e.entry), contains(entry));
  });
}
