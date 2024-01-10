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
      final c = Variable<UuidValue>(uuid, const NativeUuidType());

      expect(c.driftSqlType, isA<NativeUuidType>());
      expect(c, generates('?', [uuid]));
    });

    test('constant', () {
      final c = Constant<UuidValue>(uuid, const NativeUuidType());

      expect(c.driftSqlType, isA<NativeUuidType>());
      expect(c, generates("'$uuid'"));
    });

    test('cast', () {
      final cast = Variable('foo').cast<UuidValue>(const NativeUuidType());

      expect(cast.driftSqlType, isA<NativeUuidType>());
      expect(cast, generates('CAST(? AS uuid)', ['foo']));
    });
  });

  test('for inserts', () async {
    final sqlite3Executor = MockExecutor();
    final postgresExecutor = MockExecutor();
    when(postgresExecutor.dialect).thenReturn(SqlDialect.postgres);

    var database = TodoDb(sqlite3Executor);
    addTearDown(database.close);

    final uuid = Uuid().v4obj();
    await database
        .into(database.withCustomType)
        .insert(WithCustomTypeCompanion.insert(id: uuid));

    verify(sqlite3Executor.runInsert(
        'INSERT INTO "with_custom_type" ("id") VALUES (?)', [uuid.toString()]));

    database.close();
    database = TodoDb(postgresExecutor);

    await database
        .into(database.withCustomType)
        .insert(WithCustomTypeCompanion.insert(id: uuid));

    verify(postgresExecutor.runInsert(
        r'INSERT INTO "with_custom_type" ("id") VALUES ($1)', [uuid]));
  });

  test('for selects', () async {
    final uuid = Uuid().v4obj();

    final sqlite3Executor = MockExecutor();
    when(sqlite3Executor.runSelect(any, any)).thenAnswer((_) {
      return Future.value([
        {'id': uuid.toString()}
      ]);
    });

    final postgresExecutor = MockExecutor();
    when(postgresExecutor.dialect).thenReturn(SqlDialect.postgres);
    when(postgresExecutor.runSelect(any, any)).thenAnswer((_) {
      return Future.value([
        {'id': uuid}
      ]);
    });

    var database = TodoDb(sqlite3Executor);
    addTearDown(database.close);

    final row = await database.withCustomType.all().getSingle();
    expect(row.id, uuid);

    await database.close();
    database = TodoDb(postgresExecutor);

    final pgRow = await database.withCustomType.all().getSingle();
    expect(pgRow.id, uuid);
  });
}
