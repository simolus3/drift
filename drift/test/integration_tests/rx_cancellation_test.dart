@Tags(['integration'])
import 'package:drift/isolate.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

import 'cancellation_test_support.dart';

void main() {
  test('together with switchMap', () async {
    String slowQuery(int i) => '''
      with recursive slow(x) as (values(log_value($i)) union all select x+1 from slow where x < 1000000)
      select $i from slow;
    ''';

    final isolate = await DriftIsolate.spawn(createConnection);
    addTearDown(isolate.shutdownAll);

    final db = EmptyDb.connect(await isolate.connect());
    await db.customSelect('select 1').getSingle();

    final filter = BehaviorSubject<int>();
    addTearDown(filter.close);
    filter
        .switchMap((value) => db.customSelect(slowQuery(value)).watch())
        .listen(null);

    for (var i = 0; i < 4; i++) {
      filter.add(i);
      await pumpEventQueue();
    }

    final values = await db
        .customSelect('select get_values() r')
        .map((row) => row.read<String>('r'))
        .getSingle();

    expect(values.split(',').length, lessThan(4), reason: 'Read all $values');
  });
}
