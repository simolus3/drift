@TestOn('vm')
library;

import 'package:drift3_preview/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';
import 'package:drift_postgres/src/type.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:test/test.dart';

import '../example/main.dart';
import 'drift_postgres_test.dart';

void main() {
  final executor = PgExecutor();
  final database = DriftPostgresDatabase(executor.createConnection());

  setUpAll(() async {
    await database.usersQueries.insertOne(
      UsersCompanion.insert(name: 'test user'),
    );
  });

  tearDownAll(() async {
    await executor.clearDatabaseAndClose(database);
  });

  Future<T> eval<T extends Object>(Expression<T> expression) async {
    final query = database.selectOnly(database.users)..addColumns([expression]);
    final row = await query.getSingle();
    return row.read(expression)!;
  }

  group('array', () {
    test('length', () async {
      expect(await eval(Literal([1, 2, 3], PgTypes.bigIntArray).length), 3);
    });

    test('element access', () async {
      final array = Variable([
        {'foo': 'bar'},
        'test',
        2,
      ], PgTypes.jsonbArray);
      final element = array[Literal(3)];
      expect(
        element.sqlType,
        const PhysicalPostgresType(pg.Type.jsonb, 'jsonb'),
      );
      expect(await eval(element), 2);
    });

    test('concatenation', () async {
      final firstArray = Literal(['a', 'b', 'c'], PgTypes.textArray);
      final secondArray = Variable(['d', 'e', 'f'], PgTypes.textArray);

      expect(await eval(firstArray + secondArray), [
        'a',
        'b',
        'c',
        'd',
        'e',
        'f',
      ]);
    });
  });

  test('now', () async {
    final dartNow = DateTime.now();
    final postgresNow = await eval(now());

    expect(
      postgresNow.dateTime.millisecondsSinceEpoch,
      closeTo(dartNow.millisecondsSinceEpoch, 2000),
    );
  });

  test('random uuid', () async {
    final uuid = await eval(genRandomUuid());

    expect(uuid.version, 4);
  });
}
