import 'package:drift3_preview/drift.dart';
import 'package:drift_postgres/src/drift3_preview/drift_postgres.dart'
    hide UuidValue;
import 'package:mockito/mockito.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart' hide UuidValue;

import '../../generated/todos.dart';
import '../../test_utils.dart';
import '../../test_utils/mocks.dart';

void main() {
  final uuid = UuidValue(Uuid().v4());

  group('in expression', () {
    test('variable', () {
      final c = Variable<UuidValue>(uuid, uuidType);

      expect(c, generates('?1', [uuid.toString()]));
      expect(
        c,
        generatesWithDialect(
          r'$1',
          variables: [uuid.toString()],
          dialect: const PostgresDialect.withOptions(),
        ),
      );
    });

    test('constant', () {
      final c = Literal<UuidValue>(uuid, uuidType);

      expect(c, generates("'$uuid'"));
    });

    test('cast', () {
      final cast = Variable('foo').cast<UuidValue>(uuidType);

      expect(cast, generates('CAST(?1 AS text)', ['foo']));
      expect(
        cast,
        generatesWithDialect(
          r'CAST($1 AS uuid)',
          variables: [TypedValue(Type.text, 'foo')],
          dialect: const PostgresDialect.withOptions(),
        ),
      );
    });
  });

  test('for inserts ', () async {
    final sqlite3Executor = MockSession();
    final postgresExecutor = MockSession();

    var database = TodoDb(createConnection(sqlite3Executor));
    addTearDown(database.close);

    final uuid = UuidValue(Uuid().v4());
    await database
        .into(database.withCustomType)
        .insert(WithCustomTypeCompanion.insert(id: uuid));

    verify(
      sqlite3Executor.executeSql(
        'INSERT INTO "with_custom_type" ("id") VALUES (?1)',
        [uuid.toString()],
      ),
    );

    database.close();
    database = TodoDb(
      createConnection(postgresExecutor, dialect: PostgresDialect.new),
    );

    await database
        .into(database.withCustomType)
        .insert(WithCustomTypeCompanion.insert(id: uuid));

    verify(
      postgresExecutor.executeSql(
        r'INSERT INTO "with_custom_type" ("id") VALUES ($1)',
        [uuid.toString()],
      ),
    );
  });

  test('for selects', () async {
    final uuid = UuidValue(Uuid().v4());

    final sqlite3Executor = MockSession();
    when(sqlite3Executor.execute(any)).thenAnswer((_) async {
      return queryResult([
        {'id': uuid.toString()},
      ]);
    });

    final postgresExecutor = MockSession();
    when(postgresExecutor.execute(any)).thenAnswer((_) async {
      return queryResult([
        {'id': uuid},
      ]);
    });

    var database = TodoDb(createConnection(sqlite3Executor));
    addTearDown(database.close);

    final row = await database.select(database.withCustomType).getSingle();
    expect(row.id, uuid);

    await database.close();
    database = TodoDb(
      createConnection(postgresExecutor, dialect: PostgresDialect.new),
    );

    final pgRow = await database.select(database.withCustomType).getSingle();
    expect(pgRow.id, uuid);
  });
}
