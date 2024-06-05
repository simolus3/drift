@TestOn('vm')
library;

import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

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

  void testWith<T extends Object>(CustomSqlType<T>? type, T value) {
    test('with variable', () async {
      final variable = Variable(value, type);
      expect(await eval(variable), value);
    });

    test('with constant', () async {
      final constant = Constant(value, type);
      expect(await eval(constant), value);
    });
  }

  group('custom types pass through', () {
    group('uuid', () => testWith(PgTypes.uuid, Uuid().v4obj()));
    group(
      'interval',
      () => testWith(PgTypes.interval, Interval(months: 2, microseconds: 1234)),
    );
    group('json', () => testWith(PgTypes.json, {'foo': 'bar'}));
    group('jsonb', () => testWith(PgTypes.jsonb, {'foo': 'bar'}));
    group('point', () => testWith(PgTypes.point, pg.Point(90, -90)));
    group(
      'timestamp with timezone',
      () => testWith(PgTypes.timestampWithTimezone,
          PgDateTime(DateTime.utc(1996, 7, 8, 10, 0, 0))),
    );

    group(
      'timestamp without timezone',
      () => testWith(PgTypes.timestampNoTimezone,
          PgDateTime(DateTime.utc(1996, 7, 8, 10, 0, 0))),
    );

    group('bytea', () => testWith(null, Uint8List.fromList([1, 2, 3, 4, 5])));

    group('arrays', () {
      group(
        'boolean',
        () => testWith(PgTypes.booleanArray, [true, false, true]),
      );

      group(
        'bigint',
        () => testWith(PgTypes.bigIntArray, [1, 2, 3]),
      );

      group(
        'text',
        () => testWith(PgTypes.textArray, ['hello', 'world']),
      );

      group(
        'double',
        () => testWith(PgTypes.doubleArray, [0.0, 1.0, 0.5]),
      );

      group(
        'jsonb',
        () => testWith(PgTypes.jsonbArray, [
          true,
          {'hello': 'world'},
          3
        ]),
      );
    });
  });

  test('compare datetimes', () async {
    final time = DateTime.now();
    final before = Variable(
        PgDateTime(time.subtract(const Duration(minutes: 10))),
        PgTypes.timestampNoTimezone);
    final now = Variable(PgDateTime(time), PgTypes.timestampNoTimezone);
    final after = Variable(PgDateTime(time.add(const Duration(days: 2))),
        PgTypes.timestampNoTimezone);

    expect(await eval(before.isSmallerOrEqual(after)), isTrue);
    expect(await eval(now.isBetween(before, after)), isTrue);
  });

  test('compare dates', () async {
    final moonLanding = PgDate(year: 1969, month: 7, day: 20);
    final berlinWallFell = PgDate(year: 1989, month: 11, day: 9);

    expect(
        await eval(Variable(berlinWallFell, PgTypes.date)
            .isBiggerOrEqualValue(moonLanding)),
        isTrue);
  });

  test('bigint', () async {
    expect(await eval(Variable<BigInt>(BigInt.two)), BigInt.two);

    await expectLater(
      eval(Variable<BigInt>(BigInt.parse('9223372036854775808'))),
      throwsArgumentError,
      reason: 'Out of range',
    );
  });
}
