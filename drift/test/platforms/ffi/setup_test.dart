@TestOn('vm')
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

import '../../generated/todos.dart';

void _setup(Database db) {
  db.createFunction(
    functionName: 'my_function',
    function: (args) => 'hello from Dart',
  );
}

void main() {
  test('can use a custom setup function', () async {
    final executor = NativeDatabase.memory(setup: _setup);

    final db = TodoDb(executor);
    final row = await db.customSelect('SELECT my_function() AS r;').getSingle();

    expect(row.readString('r'), 'hello from Dart');
    await db.close();
  });

  test('custom setup is called for existing databases', () async {
    final existing = sqlite3.openInMemory();
    final executor = NativeDatabase.opened(existing, setup: _setup);
    // Needs to be false so that we can run migrations
    expect(executor.delegate.isOpen, completion(isFalse));

    final db = TodoDb(executor);
    final row = await db.customSelect('SELECT my_function() AS r;').getSingle();
    expect(row.readString('r'), 'hello from Dart');

    final nativeRow = existing.select('SELECT my_function() AS r;').single;
    expect(nativeRow['r'], 'hello from Dart');

    await db.close();
  });
}
