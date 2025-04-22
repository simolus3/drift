import 'package:drift/dialect/postgres.dart';
import 'package:drift/dialect/sqlite.dart';
import 'package:drift/drift.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import '../../generated/todos.dart';
import '../../test_utils/test_utils.dart';

void main() {
  final uuid = Uuid().v4obj();

  group('in expression', () {
    test('variable', () {
      final c = Variable<UuidValue>(uuid, (_) => const UuidType());

      expect(c.resolveType(const SqliteDialect()), isA<UuidType>());
      expect(c, generates('?1', [uuid.toString()]));
      expect(
        c,
        generatesWithOptions(r'$1',
            variables: [uuid], dialect: const PostgresDialect()),
      );
    });

    test('constant', () {
      final c = Literal<UuidValue>(uuid, (_) => const UuidType());

      expect(c.resolveType(const SqliteDialect()), isA<UuidType>());
      expect(c, generates("'$uuid'"));
    });

    test('cast', () {
      final cast = Variable('foo').cast<UuidValue>(const UuidType());

      expect(cast.resolveType(const SqliteDialect()), isA<UuidType>());
      expect(cast, generates('CAST(?1 AS text)', ['foo']));
      expect(
        cast,
        generatesWithOptions(r'CAST($1 AS uuid)',
            variables: ['foo'], dialect: const PostgresDialect()),
      );
    });
  });

  test('for inserts', () async {
    final sqlite3Executor = MockSession();
    final postgresExecutor = MockSession();

    var database = TodoDb(createConnection(sqlite3Executor));
    addTearDown(database.close);

    final uuid = Uuid().v4obj();
    await database
        .into(database.withCustomType)
        .insert(WithCustomTypeCompanion.insert(id: uuid));

    verify(sqlite3Executor.executeSql(
        'INSERT INTO "with_custom_type" ("id") VALUES (?1)',
        [uuid.toString()]));

    database.close();
    database = TodoDb(
        createConnection(postgresExecutor, dialect: const PostgresDialect()));

    await database
        .into(database.withCustomType)
        .insert(WithCustomTypeCompanion.insert(id: uuid));

    verify(postgresExecutor.executeSql(
        r'INSERT INTO "with_custom_type" ("id") VALUES ($1)', [uuid]));
  });

  test('for selects', () async {
    final uuid = Uuid().v4obj();

    final sqlite3Executor = MockSession();
    when(sqlite3Executor.execute(any)).thenAnswer((_) async {
      return queryResult([
        {'id': uuid.toString()}
      ]);
    });

    final postgresExecutor = MockSession();
    when(postgresExecutor.execute(any)).thenAnswer((_) async {
      return queryResult([
        {'id': uuid}
      ]);
    });

    var database = TodoDb(createConnection(sqlite3Executor));
    addTearDown(database.close);

    final row = await database.select(database.withCustomType).getSingle();
    expect(row.id, uuid);

    await database.close();
    database = TodoDb(
        createConnection(postgresExecutor, dialect: const PostgresDialect()));

    final pgRow = await database.select(database.withCustomType).getSingle();
    expect(pgRow.id, uuid);
  });
}
