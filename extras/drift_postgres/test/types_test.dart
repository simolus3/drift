import 'package:drift/drift.dart';
import 'package:drift_postgres/postgres.dart';
import 'package:postgres/postgres_v3_experimental.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import '../example/main.dart';

void main() {
  final database = DriftPostgresDatabase(PgDatabase(
    endpoint: PgEndpoint(
      host: 'localhost',
      database: 'postgres',
      username: 'postgres',
      password: 'postgres',
    ),
  ));

  setUpAll(() async {
    await database.users.insertOne(UsersCompanion.insert(name: 'test user'));
  });

  tearDownAll(() async {
    await database.users.deleteAll();
    await database.close();
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
    group('interval', () => testWith(PgTypes.interval, Duration(seconds: 15)));
    group('json', () => testWith(PgTypes.json, {'foo': 'bar'}));
    group('jsonb', () => testWith(PgTypes.jsonb, {'foo': 'bar'}));
    group('point', () => testWith(PgTypes.point, PgPoint(90, -90)));
    group(
      'timestamp without timezone',
      () => testWith(PgTypes.timestampNoTimezone,
          PgDateTime(DateTime.utc(1996, 7, 8, 10, 0, 0))),
    );
  });
}
