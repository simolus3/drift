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
      final c = Variable<UuidValue>(uuid, const UuidType());

      expect(c.driftSqlType, isA<UuidType>());
      expect(c, generates('?', [uuid]));
    });

    test('constant', () {
      final c = Constant<UuidValue>(uuid, const UuidType());

      expect(c.driftSqlType, isA<UuidType>());
      expect(c, generates("'$uuid'"));
    });

    test('cast', () {
      final cast = Variable('foo').cast<UuidValue>(const UuidType());

      expect(cast.driftSqlType, isA<UuidType>());
      expect(cast, generates('CAST(? AS uuid)', ['foo']));
    });
  });

  test('for inserts', () async {
    final executor = MockExecutor();
    final database = TodoDb(executor);
    addTearDown(database.close);

    final uuid = Uuid().v4obj();
    await database
        .into(database.withCustomType)
        .insert(WithCustomTypeCompanion.insert(id: uuid));

    verify(executor
        .runInsert('INSERT INTO "with_custom_type" ("id") VALUES (?)', [uuid]));
  });

  test('for selects', () async {
    final executor = MockExecutor();
    final database = TodoDb(executor);
    addTearDown(database.close);

    final uuid = Uuid().v4obj();
    when(executor.runSelect(any, any)).thenAnswer((_) {
      return Future.value([
        {'id': uuid}
      ]);
    });

    final row = await database.withCustomType.all().getSingle();
    expect(row.id, uuid);
  });
}
