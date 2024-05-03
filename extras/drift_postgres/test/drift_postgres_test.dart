import 'package:drift_postgres/drift_postgres.dart';
import 'package:drift_testcases/tests.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:test/test.dart';

class PgExecutor extends TestExecutor {
  @override
  bool get supportsReturning => true;

  @override
  bool get supportsNestedTransactions => true;

  @override
  DatabaseConnection createConnection() {
    return DatabaseConnection(PgDatabase(
      endpoint: pg.Endpoint(
        host: 'localhost',
        database: 'postgres',
        username: 'postgres',
        password: 'postgres',
      ),
      settings: pg.ConnectionSettings(sslMode: pg.SslMode.disable),
    ));
  }

  @override
  Future clearDatabaseAndClose(GeneratedDatabase db) async {
    await db.customStatement('DROP SCHEMA public CASCADE;');
    await db.customStatement('CREATE SCHEMA public;');
    await db.customStatement('GRANT ALL ON SCHEMA public TO postgres;');
    await db.customStatement('GRANT ALL ON SCHEMA public TO public;');
    await db.close();
  }

  @override
  Future<void> deleteData() async {}
}

void main() {
  runAllTests(PgExecutor());

  // Regression for https://github.com/simolus3/drift/issues/2981
  group('binding', () {
    test('null', () async {
      await testParamBinding(
        columnType: 'INTEGER',
        input: null,
        output: null,
      );
    });

    test('BigInt()', () async {
      await testParamBinding(
        columnType: 'INT8',
        input: BigInt.from(123),
        output: 123,
      );
    });

    test('BigInt() exceeds range', () async {
      await testBindingError(
        columnType: 'INT8',
        input: BigInt.parse('9223372036854775808'),
        matcher: isA<Exception>(),
      );
    });

    test('bytea', () async {
      await testParamBinding(
        columnType: 'BYTEA',
        input: Uint8List.fromList([1, 2, 3]),
        output: Uint8List.fromList([1, 2, 3]),
      );
    });

    group('implicit casts', () {
      test('text to int', () async {
        await testParamBinding(
          columnType: 'INTEGER',
          input: '123',
          output: 123,
        );
      });

      test('int to double', () async {
        await testParamBinding(
          columnType: 'FLOAT8',
          input: 123,
          output: 123.0,
        );
      });

      test('text to double', () async {
        await testParamBinding(
          columnType: 'FLOAT8',
          input: '1.56',
          output: 1.56,
        );
      });
    });
  });
}

Future<void> testParamBinding({
  required String columnType,
  required Object? input,
  required Object? output,
}) async {
  final executor = PgExecutor();
  final db = Database(executor.createConnection());
  addTearDown(() => executor.clearDatabaseAndClose(db));

  await db.customStatement('''
CREATE TABLE mytable (
  id INTEGER PRIMARY KEY NOT NULL,
  value $columnType
);
''');

  await db.customInsert(
    r'INSERT INTO mytable (id, value) VALUES (1, $1);',
    variables: [Variable(input)],
  );

  final result = await db.customSelect('SELECT * FROM mytable;').getSingle();
  expect(result.data['value'], output);
}

Future<void> testBindingError({
  required String columnType,
  required Object? input,
  required Matcher matcher,
}) async {
  final executor = PgExecutor();
  final db = Database(executor.createConnection());
  addTearDown(() => executor.clearDatabaseAndClose(db));

  await db.customStatement('''
CREATE TABLE mytable (
  id INTEGER PRIMARY KEY NOT NULL,
  value $columnType
);
''');

  await expectLater(
    () => db.customInsert(
      r'INSERT INTO mytable (id, value) VALUES (1, $1);',
      variables: [Variable(input)],
    ),
    throwsA(matcher),
  );
}
