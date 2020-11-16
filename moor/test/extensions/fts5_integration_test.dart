@Tags(['integration'])
@TestOn('vm')
import 'package:moor/ffi.dart';
import 'package:test/test.dart';

import '../data/tables/custom_tables.dart';

void main() {
  test('fts5 integration test', () async {
    final db = CustomTablesDb(VmDatabase.memory());

    await db.into(db.email).insert(EmailCompanion.insert(
        sender: 'foo@example.org', title: 'Hello world', body: 'Test email'));

    await db.into(db.email).insert(EmailCompanion.insert(
        sender: 'another@example.org', title: 'Good morning', body: 'hello'));

    final results = await db.searchEmails(term: 'hello').get();

    expect(results, hasLength(2));
  });
}
