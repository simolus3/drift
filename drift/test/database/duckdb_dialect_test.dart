import 'package:drift/drift.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils/test_utils.dart';

void main() {
  String writeColumn(GeneratedColumn<Object> column) {
    final context = stubContext(dialect: SqlDialect.duckdb);
    column.writeColumnDefinition(context);
    return context.sql;
  }

  group('schema generation', () {
    test('writes BIGINT for integer columns', () {
      expect(
        writeColumn(
          GeneratedColumn<int>('value', 'tbl', false, type: DriftSqlType.int),
        ),
        '"value" BIGINT NOT NULL',
      );
    });

    test('writes BIGINT for int64 columns', () {
      expect(
        writeColumn(
          GeneratedColumn<BigInt>(
            'value',
            'tbl',
            false,
            type: DriftSqlType.bigInt,
          ),
        ),
        '"value" BIGINT NOT NULL',
      );
    });

    test('writes BOOLEAN for boolean columns', () {
      expect(
        writeColumn(
          GeneratedColumn<bool>('value', 'tbl', false, type: DriftSqlType.bool),
        ),
        '"value" BOOLEAN NOT NULL',
      );
    });

    test('writes DOUBLE for real columns', () {
      expect(
        writeColumn(
          GeneratedColumn<double>(
            'value',
            'tbl',
            false,
            type: DriftSqlType.double,
          ),
        ),
        '"value" DOUBLE NOT NULL',
      );
    });
  });

  group('variables', () {
    test('use question mark placeholders', () {
      expect(
        const Variable<int>(1),
        generatesWithOptions('?', variables: [1], dialect: SqlDialect.duckdb),
      );
    });

    test('do not generate sqlite-style indexed placeholders', () {
      final context = stubContext(dialect: SqlDialect.duckdb)
        ..explicitVariableIndex = 3;

      const Variable<int>(1).writeInto(context);

      expect(context.sql, '?');
      expect(context.boundVariables, [1]);
    });
  });

  group('casts', () {
    test('cast<int>() uses BIGINT', () {
      expect(
        const Variable<int>(1).cast<int>(),
        generatesWithOptions(
          'CAST(? AS BIGINT)',
          variables: [1],
          dialect: SqlDialect.duckdb,
        ),
      );
    });

    test('cast<BigInt>() uses BIGINT', () {
      expect(
        Variable<BigInt>(BigInt.one).cast<BigInt>(),
        generatesWithOptions(
          'CAST(? AS BIGINT)',
          variables: [BigInt.one],
          dialect: SqlDialect.duckdb,
        ),
      );
    });
  });

  group('query generation', () {
    late TodoDb db;
    late MockExecutor executor;

    setUp(() {
      executor = MockExecutor();
      when(executor.dialect).thenReturn(SqlDialect.duckdb);
      db = TodoDb(executor);
    });

    test('inserts with question mark placeholders', () async {
      await db
          .into(db.tableWithoutPK)
          .insert(
            CustomRowClass.map(
              42,
              3.1415,
              webSafeInt: BigInt.one,
              custom: MyCustomObject('custom'),
            ).toInsertable(),
          );

      verify(
        executor.runInsert(
          'INSERT INTO "table_without_p_k" '
          '("not_really_an_id", "some_float", "web_safe_int", "custom") '
          'VALUES (?, ?, ?, ?)',
          [42, 3.1415, BigInt.one, anything],
        ),
      );
    });

    test('selects with question mark placeholders', () async {
      when(executor.runSelect(any, any)).thenAnswer((_) async => []);

      await (db.select(
        db.tableWithoutPK,
      )..where((t) => t.notReallyAnId.equals(42))).get();

      verify(
        executor.runSelect(
          'SELECT * FROM "table_without_p_k" WHERE "not_really_an_id" = ?;',
          [42],
        ),
      );
    });

    test('supports RETURNING * for inserts', () async {
      when(executor.runSelect(any, any)).thenAnswer(
        (_) async => [
          {
            'id': 1,
            'desc': 'description',
            'description_in_upper_case': 'DESCRIPTION',
            'priority': 1,
          },
        ],
      );

      await db
          .into(db.categories)
          .insertReturning(
            CategoriesCompanion.insert(description: 'description'),
          );

      verify(
        executor.runSelect(
          'INSERT INTO "categories" ("desc") VALUES (?) RETURNING *',
          ['description'],
        ),
      );
    });
  });
}
