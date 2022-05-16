@TestOn('browser')
import 'package:drift/drift.dart';
import 'package:drift/web.dart';
import 'package:test/test.dart';

void main() async {
  test('supports BigInt if enabled', () async {
    final db = WebDatabase.withStorage(DriftWebStorage.volatile(),
        readIntsAsBigInt: true);
    await db.ensureOpen(_EmptyUser());
    addTearDown(db.close);

    var result = await db.runSelect('SELECT 1 AS r', []);
    expect(result.single, {'r': BigInt.one});

    // Unlike package:sqlite3, sql-js does not properly support BigInts and
    // binds them as strings.
    result = await db.runSelect('SELECT ? AS r', [BigInt.zero]);
    expect(result.single, {'r': '0'});
  });

  test('does not support BigInt if disabled', () async {
    final db = WebDatabase.withStorage(DriftWebStorage.volatile(),
        readIntsAsBigInt: false);
    await db.ensureOpen(_EmptyUser());
    addTearDown(db.close);

    final result = await db.runSelect('SELECT 1 AS r', []);
    expect(result.single, {'r': 1});

    await expectLater(
        () => db.runSelect('SELECT typeof(?) AS r', [BigInt.zero]),
        throwsA(isA<AssertionError>()));
  });
}

class _EmptyUser extends QueryExecutorUser {
  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) {
    return Future.value();
  }

  @override
  int get schemaVersion => 1;
}
