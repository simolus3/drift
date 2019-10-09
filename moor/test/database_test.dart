import 'package:test/test.dart';
import 'package:moor/moor.dart';

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
        await customSelectQuery(
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
    MockQueryExecutor queryExecutor;

    setUp(() {
      executor = MockExecutor();
      queryExecutor = MockQueryExecutor();
      db = _FakeDb(SqlTypeSystem.defaultInstance, executor);
    });

    test('onCreate', () async {
      await db.handleDatabaseCreation(executor: queryExecutor);
      verify(queryExecutor.call('created'));
    });

    test('onUpgrade', () async {
      await db.handleDatabaseVersionChange(
          executor: queryExecutor, from: 2, to: 3);
      verify(queryExecutor.call('updated from 2 to 3'));
    });

    test('beforeOpen', () async {
      await db.beforeOpenCallback(executor, const OpeningDetails(3, 4));
      verify(executor.runSelect('opened: 3 to 4', []));
    });
  });
}
