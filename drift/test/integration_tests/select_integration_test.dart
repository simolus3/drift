@TestOn('vm')
import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

import '../data/tables/todos.dart';

void main() {
  late TodoDb db;

  setUp(() {
    db = TodoDb(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('can use random ordering', () async {
    await db.batch((b) {
      b.insertAll(db.users, [
        for (var i = 0; i < 1000; i++)
          UsersCompanion.insert(
              name: 'user name', profilePicture: Uint8List(0)),
      ]);
    });

    final rows = await (db.select(db.users)
          ..orderBy([(_) => OrderingTerm.random()]))
        .get();
    expect(rows.isSorted((a, b) => a.id.compareTo(b.id)), isFalse);
  });
}
