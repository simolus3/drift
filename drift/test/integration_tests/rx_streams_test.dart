import 'package:mockito/mockito.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils/test_utils.dart';

void main() {
  late TodoDb db;
  late MockExecutor executor;
  setUp(() {
    executor = MockExecutor();
    db = TodoDb(executor);
  });

  test('drift streams can be used with switchMap in rxdart', () async {
    // Regression test for https://github.com/simolus3/drift/issues/500
    when(executor.runSelect(any, any)).thenAnswer((i) async {
      final sql = i.positionalArguments.first as String;

      return [
        if (sql.contains("'a'")) {'a': 'a'} else {'b': 'b'}
      ];
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
