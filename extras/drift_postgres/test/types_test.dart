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

  group('custom types pass through', () {
    void testWith<T extends Object>(CustomSqlType<T> type, T value) {
      test('with variable', () async {
        final variable = Variable(value, type);
        final query = database.selectOnly(database.users)
          ..addColumns([variable]);
        final row = await query.getSingle();
        expect(row.read(variable), value);
      });

      test('with constant', () async {
        final constant = Constant(value, type);
        final query = database.selectOnly(database.users)
          ..addColumns([constant]);
        final row = await query.getSingle();
        expect(row.read(constant), value);
      });
    }

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
  });
}
