import 'package:end_to_end_testing/tables.dart';
import 'package:end_to_end_testing/vm_database.dart';
import 'package:test_api/test_api.dart';

void main() {
  test('Generates tables', () async* {
    final db = ExampleDb(MemoryDatabase());

    await db.handleDatabaseCreation(executor: db.executor.runCustom);
  });
}