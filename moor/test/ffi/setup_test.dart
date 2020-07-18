@TestOn('vm')
import 'package:moor/ffi.dart';
import 'package:test/test.dart';

import '../data/tables/todos.dart';

void main() {
  test('can use a custom setup function', () async {
    final executor = VmDatabase.memory(setup: (db) {
      db.createFunction(
        functionName: 'my_function',
        function: (args) => 'hello from Dart',
      );
    });

    final db = TodoDb(executor);
    final row = await db.customSelect('SELECT my_function() AS r;').getSingle();

    expect(row.readString('r'), 'hello from Dart');
  });
}
