import 'dart:async';

import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../test_utils/test_utils.dart';

class _TestDb extends GeneratedDatabase {
  _TestDb() : super(testInMemoryDatabase());
  @override
  final List<TableInfo> allTables = const [];
  @override
  final int schemaVersion = 1;
}

Future<int> _selectOne(_TestDb db) =>
    db.customSelect('select 1 a').map((row) => row.read<int>('a')).getSingle();

void main() {
  for (final useTransaction in [false, true]) {
    test('query after db.close, useTransaction=$useTransaction', () async {
      final db = _TestDb();
      expect(await _selectOne(db), 1);
      await db.close();

      expect(
        () async {
          if (useTransaction) {
            await db.transaction(() => _selectOne(db));
          } else {
            await _selectOne(db);
          }
        },
        throwsA(isA<StateError>().having((e) => e.message, 'message',
            contains("Can't re-open a database after closing it."))),
      );
    });
  }
}
