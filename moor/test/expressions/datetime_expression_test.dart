//@dart=2.9
import 'package:moor/moor.dart';
import 'package:test/test.dart';

import '../data/utils/expect_equality.dart';
import '../data/utils/expect_generated.dart';

typedef _Extractor = Expression<int> Function(Expression<DateTime> d);

void main() {
  final column = GeneratedDateTimeColumn('val', null, false);

  group('extracting information via top-level method', () {
    final expectedResults = <_Extractor, String>{
      (d) => d.year: "CAST(strftime('%Y', val, 'unixepoch') AS INTEGER)",
      (d) => d.month: "CAST(strftime('%m', val, 'unixepoch') AS INTEGER)",
      (d) => d.day: "CAST(strftime('%d', val, 'unixepoch') AS INTEGER)",
      (d) => d.hour: "CAST(strftime('%H', val, 'unixepoch') AS INTEGER)",
      (d) => d.minute: "CAST(strftime('%M', val, 'unixepoch') AS INTEGER)",
      (d) => d.second: "CAST(strftime('%S', val, 'unixepoch') AS INTEGER)",
    };

    expectedResults.forEach((key, value) {
      test('should extract field', () {
        final ctx = GenerationContext(SqlTypeSystem.defaultInstance, null);
        key(column).writeInto(ctx);

        expect(ctx.sql, value);

        expectEquals(key(column), key(column));
      });
    });
  });

  test('can cast datetimes to unix timestamps without rewriting', () {
    final expr = currentDateAndTime.secondsSinceEpoch + const Constant(10);
    final ctx = GenerationContext(SqlTypeSystem.defaultInstance, null);
    expr.writeInto(ctx);

    expect(ctx.sql, 'strftime(\'%s\', CURRENT_TIMESTAMP) + 10');
  });

  test('plus and minus durations', () {
    final expr = currentDateAndTime +
        const Duration(days: 3) -
        const Duration(seconds: 5);

    expect(expr,
        generates('strftime(\'%s\', CURRENT_TIMESTAMP) + ? - ?', [259200, 5]));
  });
}
