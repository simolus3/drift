@TestOn('vm')
import 'package:drift/src/sqlite3/database.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

import '../../test_utils/database_vm.dart';

void main() {
  preferLocalSqlite3();

  test("lru/mru order and remove callback", () {
    final cache = PreparedStatementsCache(maxSize: 3);
    final database = sqlite3.openInMemory();
    addTearDown(database.dispose);

    expect(cache.use('SELECT 1'), isNull);
    cache.addNew('SELECT 1', database.prepare('SELECT 1'));
    cache.addNew('SELECT 2', database.prepare('SELECT 2'));
    cache.addNew('SELECT 3', database.prepare('SELECT 3'));

    expect(cache.use('SELECT 3'), isNotNull);
    expect(cache.use('SELECT 1'), isNotNull);

    // Inserting another statement should remove #2, which is now the LRU
    cache.addNew('SELECT 4', database.prepare('SELECT 4'));
    expect(cache.use('SELECT 2'), isNull);
    expect(cache.use('SELECT 1'), isNotNull);
  });
}
