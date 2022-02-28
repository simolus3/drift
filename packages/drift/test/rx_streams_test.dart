import 'package:mockito/mockito.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

import 'data/tables/todos.dart';
import 'data/utils/mocks.dart';

void main() {
  late TodoDb db;
  late MockExecutor executor;
  setUp(() {
    executor = MockExecutor();
    db = TodoDb(executor);
  });

  test('drift streams can be used with switchMap in rxdart', () async {
    // Regression test for https://github.com/simolus3/moor/issues/500
    when(executor.runSelect(any, any)).thenAnswer((i) async {
      final sql = i.positionalArguments.first as String;

      return [
        if (sql.contains("'a'")) {'a': 'a'} else {'b': 'b'}
      ];
    });

    final a = db
        .customSelect("select 'a' as a")
        .map(($) => $.readString('a'))
        .watchSingle();
    final b = db
        .customSelect("select 'b' as b")
        .map(($) => $.readString('b'))
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
