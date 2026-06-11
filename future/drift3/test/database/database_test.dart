import 'package:drift3/drift.dart';
import 'package:drift_postgres/src/drift3_preview/drift_postgres.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils.dart';
import '../test_utils/mocks.dart';

final class _FakeDb extends GeneratedDatabase {
  _FakeDb(super.implementation);

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await customStatement('created');
      },
      onUpgrade: (m, from, to) async {
        await customStatement('updated from $from to $to');
      },
      beforeOpen: (details) async {
        // this fake select query is verified via mocks
        await customSelect(
          'opened: ${details.versionBefore} to ${details.versionNow}',
        ).get();
      },
    );
  }

  @override
  DatabaseSchema get schema => DatabaseSchema.empty;

  @override
  int schemaVersion = 1;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('status of OpeningDetails', () {
    expect(const OpeningDetails(null, 1).wasCreated, true);
    expect(const OpeningDetails(2, 4).wasCreated, false);
    expect(const OpeningDetails(2, 4).hadUpgrade, true);
    expect(const OpeningDetails(4, 4).wasCreated, false);
    expect(const OpeningDetails(4, 4).hadUpgrade, false);
  });

  group('callbacks', () {
    late _FakeDb db;
    late MockSession session;

    setUp(() {
      session = MockSession();
      db = _FakeDb(createConnection(session));
    });

    test('onCreate', () async {
      when(session.schemaVersion).thenAnswer((_) async => 0);
      await db.initialize();
      verify(session.executeSql('created'));
    });

    test('onUpgrade', () async {
      db.schemaVersion = 3;
      when(session.schemaVersion).thenAnswer((_) async => 2);
      await db.initialize();

      verify(session.executeSql('updated from 2 to 3'));
    });

    test('beforeOpen', () async {
      db.schemaVersion = 4;
      when(session.schemaVersion).thenAnswer((_) async => 3);
      await db.initialize();

      verify(session.executeSql('opened: 3 to 4'));
    });
  });

  test('creates and attaches daos', () async {
    final executor = MockSession();
    final db = TodoDb(createConnection(executor));

    await db.someDao.todosForUser(user: RowId(1)).get();

    verify(
      executor.executeSql(
        contains(
          'INNER JOIN shared_todos AS st ON st.todo = t.id INNER JOIN users',
        ),
        [1],
      ),
    );
  });

  test('closing the database closes the executor', () async {
    final executor = MockSession();
    final db = TodoDb(createConnection(executor));

    await db.initialize();
    await db.close();

    verify(executor.close());
  });

  test('closing the database immediately does nothing', () async {
    final executor = MockSession();
    final db = TodoDb(createConnection(executor));
    await db.close();

    verifyNever(executor.close());
  });

  test('throws when migration fails', () async {
    final executor = MockSession();
    when(executor.schemaVersion).thenAnswer((_) async => 0);
    when(executor.execute(any)).thenAnswer((_) => Future.error('error'));

    final db = TodoDb(createConnection(executor));
    expect(db.customSelect('SELECT 1').getSingle(), throwsA('error'));
  });

  test('zone database is ignored for operations on another database', () async {
    final ex1 = MockSession();
    final ex2 = MockSession();

    final db1 = TodoDb(createConnection(ex1));
    final db2 = TodoDb(createConnection(ex2));
    addTearDown(db1.close);
    addTearDown(db2.close);

    await db1.transaction(() async {
      clearInteractions(ex1);
      await db2.customSelect('SELECT 1').get();
    });

    verify(ex2.executeSql('SELECT 1'));
    verifyNever(ex1.execute(any));
  });

  test('disallows zero as a schema version', () async {
    var executor = MockSession();
    when(executor.schemaVersion).thenAnswer((_) async => 0);

    var db = TodoDb(createConnection(executor))..schemaVersion = 0;
    await expectLater(db.customSelect('SELECT 1').get(), throwsStateError);

    db = TodoDb(createConnection(executor))..schemaVersion = -1;
    await expectLater(db.customSelect('SELECT 1').get(), throwsStateError);

    db = TodoDb(createConnection(executor))..schemaVersion = 1;
    await expectLater(db.customSelect('SELECT 1').get(), completes);
  });

  test('expand variables', () {
    final db = TodoDb();
    expect(db.$expandVar(4, 0), '');
    expect(db.$expandVar(1, 3), '?2,?3,?4');

    final postgresDb = TodoDb(
      DriftConnection(
        dialect: PostgresDialect(),
        openConnection: () => throw UnsupportedError('stub'),
      ),
    );
    expect(postgresDb.$expandVar(1, 3), r'$2,$3,$4');
  });
}
