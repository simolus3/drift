import 'dart:typed_data';

import 'package:drift3_preview/drift.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../generated/todos.dart';
import '../../test_utils.dart';
import '../../test_utils/mocks.dart';
import '../../test_utils/test_query_store.dart';

void main() {
  late TodoDb db;
  late MockSession session;
  late TestStreamQueryStore streamQueries;

  setUp(() {
    session = MockSession();
    streamQueries = TestStreamQueryStore();
    db = TodoDb(createConnection(session, streams: streamQueries));
  });

  group('compiled custom queries', () {
    // defined query: SELECT * FROM todos WHERE title = ?2 OR id IN ? OR title = ?1
    test('work with arrays', () async {
      await db.initialize();
      clearInteractions(session);

      await db.withIn('one', 'two', [RowId(1), RowId(2), RowId(3)]).get();

      verify(
        session.executeSql(
          'SELECT "_s:0".id, "_s:0".title, "_s:0".content, "_s:0".target_date, "_s:0".category, "_s:0".status FROM todos AS "_s:0" WHERE "_s:0".title = ?2 OR "_s:0".id IN (?3,?4,?5) OR "_s:0".title = ?1',
          ['one', 'two', 1, 2, 3],
        ),
      );
    });
  });

  test('custom select reads values', () async {
    final time = DateTime.utc(2019, 10, 1);
    final timeAsText = time.toIso8601String();

    when(session.execute(any)).thenAnswer((i) async {
      return queryResult([
        <String, dynamic>{
          'bool': true,
          'int': 3,
          'double': 3.14,
          'dateTime': timeAsText,
          'blob': Uint8List.fromList([1, 2, 3]),
          'null': null,
        },
      ]);
    });

    final [row] = await db.customSelect('').get();
    expect(row.read<bool>('bool'), isTrue);
    expect(row.read<int>('int'), 3);
    expect(row.read<double>('double'), 3.14);
    expect(row.read<DateTime>('dateTime'), time);
    expect(row.read<Uint8List>('blob'), Uint8List.fromList([1, 2, 3]));

    expect(row.readNullable<bool>('bool'), isTrue);
    expect(row.readNullable<bool>('null'), isNull);
    expect(row.readNullable<int>('int'), 3);
    expect(row.readNullable<int>('null'), isNull);
    expect(row.readNullable<double>('double'), 3.14);
    expect(row.readNullable<double>('null'), isNull);
    expect(row.readNullable<DateTime>('dateTime'), time);
    expect(row.readNullable<DateTime>('null'), isNull);
    expect(row.readNullable<Uint8List>('blob'), Uint8List.fromList([1, 2, 3]));
    expect(row.readNullable<Uint8List>('null'), isNull);
  });

  test('custom update informs stream queries', () async {
    await db.customUpdate(
      'UPDATE tbl SET a = ?',
      variables: [db.mapValue(BuiltinDriftType.text, 'hi')],
      updates: {db.users},
    );

    verify(session.executeSql('UPDATE tbl SET a = ?', ['hi']));
    expect(streamQueries.recordedUpdates, {
      const TableUpdate('users', kind: UpdateKind.update),
    });
  });

  test('custom insert', () async {
    when(session.execute(any)).thenAnswer((i) async {
      return queryResult([], lastInsertRowId: 32);
    });

    final id = await db.customInsert(
      'fake insert',
      variables: [db.mapValue(BuiltinDriftType.int, 3)],
    );
    expect(id, 32);

    // shouldn't call stream queries - we didn't set the updates parameter
    expect(streamQueries.recordedUpdates, isEmpty);
  });

  test(
    'custom statement',
    () async {
      // regression test for https://github.com/simolus3/drift/issues/199 - the
      // mock will throw when used before opening
      expect(db.customStatement('UPDATE tbl SET a = b'), completes);
    },
    onPlatform: const {
      'js': [
        Skip('Blocked by https://github.com/dart-lang/mockito/issues/198'),
      ],
    },
  );
}
