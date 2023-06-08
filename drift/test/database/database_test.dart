import 'package:drift/drift.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils/test_utils.dart';

class _FakeDb extends GeneratedDatabase {
  _FakeDb(QueryExecutor executor) : super(executor);

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
                'opened: ${details.versionBefore} to ${details.versionNow}')
            .get();
      },
    );
  }

  @override
  List<TableInfo> get allTables => [];
  @override
  int get schemaVersion => 1;
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
    late MockExecutor executor;

    setUp(() {
      executor = MockExecutor();
      db = _FakeDb(executor);
    });

    test('onCreate', () async {
      await db.beforeOpen(executor, const OpeningDetails(null, 1));
      verify(executor.runCustom('created', any));
    });

    test('onUpgrade', () async {
      await db.beforeOpen(executor, const OpeningDetails(2, 3));
      verify(executor.runCustom('updated from 2 to 3', any));
    });

    test('beforeOpen', () async {
      await db.beforeOpen(executor, const OpeningDetails(3, 4));
      verify(executor.runSelect('opened: 3 to 4', []));
    });
  });

  test('creates and attaches daos', () async {
    final executor = MockExecutor();
    final db = TodoDb(executor);

    await db.someDao.todosForUser(user: 1).get();

    verify(executor.runSelect(argThat(contains('SELECT t.* FROM todos')), [1]));
  });

  test('closing the database closes the executor', () async {
    final executor = MockExecutor();
    final db = TodoDb(executor);

    await db.close();

    verify(executor.close());
  });

  test('throws when migration fails', () async {
    final executor = MockExecutor(const OpeningDetails(null, 1));
    when(executor.runCustom(any, any)).thenAnswer((_) => Future.error('error'));

    final db = TodoDb(executor);
    expect(db.customSelect('SELECT 1').getSingle(), throwsA('error'));
  });

  test('zone database is ignored for operations on another database', () async {
    final ex1 = MockExecutor();
    final ex2 = MockExecutor();

    final db1 = TodoDb(ex1);
    final db2 = TodoDb(ex2);
    addTearDown(db1.close);
    addTearDown(db2.close);

    await db1.transaction(() async {
      await db2.customSelect('SELECT 1').get();
    });

    verify(ex2.runSelect('SELECT 1', []));
    verifyNever(ex2.runSelect(any, any));
  });

  test('disallows zero as a schema version', () async {
    var db = TodoDb(MockExecutor(OpeningDetails(null, 0)))..schemaVersion = 0;
    await expectLater(db.customSelect('SELECT 1').get(), throwsStateError);

    db = TodoDb(MockExecutor(OpeningDetails(null, 0)))..schemaVersion = -1;
    await expectLater(db.customSelect('SELECT 1').get(), throwsStateError);

    db = TodoDb(MockExecutor(OpeningDetails(null, 0)))..schemaVersion = 1;
    await expectLater(db.customSelect('SELECT 1').get(), completes);
  });
}
