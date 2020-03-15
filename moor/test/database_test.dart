import 'package:test/test.dart';
import 'package:moor/moor.dart';

import 'data/tables/todos.dart';
import 'data/utils/mocks.dart';

class _FakeDb extends GeneratedDatabase {
  _FakeDb(SqlTypeSystem types, QueryExecutor executor) : super(types, executor);

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.issueCustomQuery('created');
      },
      onUpgrade: (m, from, to) async {
        await m.issueCustomQuery('updated from $from to $to');
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
  moorRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('status of OpeningDetails', () {
    expect(const OpeningDetails(null, 1).wasCreated, true);
    expect(const OpeningDetails(2, 4).wasCreated, false);
    expect(const OpeningDetails(2, 4).hadUpgrade, true);
    expect(const OpeningDetails(4, 4).wasCreated, false);
    expect(const OpeningDetails(4, 4).hadUpgrade, false);
  });

  group('callbacks', () {
    _FakeDb db;
    MockExecutor executor;

    setUp(() {
      executor = MockExecutor();
      db = _FakeDb(SqlTypeSystem.defaultInstance, executor);
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

    await db.someDao.todosForUser(1).get();

    verify(executor.runSelect(argThat(contains('SELECT t.* FROM todos')), [1]));
  });

  test('closing the database closes the executor', () async {
    final executor = MockExecutor();
    final db = TodoDb(executor);

    await db.close();

    verify(executor.close());
  });
}
