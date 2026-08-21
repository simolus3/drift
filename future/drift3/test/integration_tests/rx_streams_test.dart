import 'package:drift3_preview/drift.dart';
import 'package:mockito/mockito.dart';
import 'package:rxdart/transformers.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils.dart';
import '../test_utils/mocks.dart';

void main() {
  late TodoDb db;
  late MockSession executor;
  setUp(() {
    executor = MockSession();
    db = TodoDb(createConnection(executor));
  });

  test('drift streams can be used with switchMap in rxdart', () async {
    // Regression test for https://github.com/simolus3/drift/issues/500
    await db.initialize();
    when(executor.execute(any)).thenAnswer((i) async {
      final info = i.positionalArguments.first as StatementInfo;
      final sql = info.sql;

      return queryResult([
        if (sql.contains("'a'")) {'a': 'a'} else {'b': 'b'},
      ]);
    });

    final a = db
        .customSelect("select 'a' as a")
        .map(($) => $.read<String>('a'))
        .watchSingle();
    final b = db
        .customSelect("select 'b' as b")
        .map(($) => $.read<String>('b'))
        .watchSingle();
    final c = a.switchMap((_) => b);
    expect(await a.first, 'a');
    expect(await a.first, 'a');
    expect(await b.first, 'b');
    expect(await b.first, 'b');
    expect(await c.first, 'b');
    expect(await c.first, 'b');
  });
}
