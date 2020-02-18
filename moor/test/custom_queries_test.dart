import 'package:moor/moor.dart';
import 'package:test/test.dart';

import 'data/tables/todos.dart';
import 'data/utils/mocks.dart';

// ignore_for_file: lines_longer_than_80_chars

void main() {
  TodoDb db;
  MockExecutor executor;
  MockStreamQueries streamQueries;

  setUp(() {
    executor = MockExecutor();
    streamQueries = MockStreamQueries();

    final connection = createConnection(executor, streamQueries);
    db = TodoDb.connect(connection);
  });

  group('compiled custom queries', () {
    // defined query: SELECT * FROM todos WHERE title = ?2 OR id IN ? OR title = ?1
    test('work with arrays', () async {
      await db.withIn('one', 'two', [1, 2, 3]).get();

      verify(
        executor.runSelect(
          'SELECT * FROM todos WHERE title = ?2 OR id IN (?3, ?4, ?5) OR title = ?1',
          ['one', 'two', 1, 2, 3],
        ),
      );
    });
  });

  test('custom select reads values', () async {
    final time = DateTime(2019, 10, 1);
    final unix = time.millisecondsSinceEpoch ~/ 1000;

    when(executor.runSelect(any, any)).thenAnswer((i) {
      return Future.value([
        <String, dynamic>{
          'bool': true,
          'int': 3,
          'double': 3.14,
          'dateTime': unix,
          'blob': Uint8List.fromList([1, 2, 3]),
        }
      ]);
    });

    final rows = await db.customSelect('').get();
    final row = rows.single;

    expect(row.readBool('bool'), isTrue);
    expect(row.readInt('int'), 3);
    expect(row.readDouble('double'), 3.14);
    expect(row.readDateTime('dateTime'), time);
    expect(row.readBlob('blob'), Uint8List.fromList([1, 2, 3]));
  });

  test('custom update informs stream queries', () async {
    await db.customUpdate('UPDATE tbl SET a = ?',
        variables: [Variable.withString('hi')], updates: {db.users});

    verify(executor.runUpdate('UPDATE tbl SET a = ?', ['hi']));
    verify(streamQueries.handleTableUpdates({db.users}));
  });

  test('custom insert', () async {
    when(executor.runInsert(any, any)).thenAnswer((_) => Future.value(32));

    final id =
        await db.customInsert('fake insert', variables: [Variable.withInt(3)]);
    expect(id, 32);

    // shouldn't call stream queries - we didn't set the updates parameter
    verifyNever(streamQueries.handleTableUpdates(any));
  });

  test('custom statement', () async {
    // regression test for https://github.com/simolus3/moor/issues/199 - the
    // mock will throw when used before opening
    expect(db.customStatement('UPDATE tbl SET a = b'), completes);
  }, onPlatform: const {
    'js': [Skip('Blocked by https://github.com/dart-lang/mockito/issues/198')]
  });
}
