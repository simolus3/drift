import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';
import 'package:test/test.dart';

import '../example/main.dart';
import 'drift_postgres_test.dart';

void main() {
  final executor = PgExecutor();
  final database = DriftPostgresDatabase(executor.createConnection());

  setUpAll(() async {
    await database.users.insertOne(UsersCompanion.insert(name: 'test user'));
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
      expect(await eval(Constant([1, 2, 3], PgTypes.bigIntArray).length), 3);
    });

    test('element access', () async {
      final array = Variable(
        [
          {'foo': 'bar'},
          'test',
          2,
        ],
        PgTypes.jsonbArray,
      );
      final element = array[Constant(3)];
      expect(element.driftSqlType, PgTypes.jsonb);
      expect(await eval(element), 2);
    });

    test('concatenation', () async {
      final firstArray = Constant(['a', 'b', 'c'], PgTypes.textArray);
      final secondArray = Variable(['d', 'e', 'f'], PgTypes.textArray);

      expect(
          await eval(firstArray + secondArray), ['a', 'b', 'c', 'd', 'e', 'f']);
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
