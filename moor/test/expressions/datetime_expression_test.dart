import 'package:moor/moor.dart';
import 'package:test/test.dart';

import '../data/utils/expect_equality.dart';

// ignore_for_file: deprecated_member_use_from_same_package

typedef _Extractor = Expression<int, IntType> Function(
    Expression<DateTime, DateTimeType> d);

/// Tests the top level [year], [month], ..., [second] methods
void main() {
  final column = GeneratedDateTimeColumn('val', null, false);

  group('extracting information via top-level method', () {
    final expectedResults = <_Extractor, String>{
      year: 'CAST(strftime("%Y", val, "unixepoch") AS INTEGER)',
      month: 'CAST(strftime("%m", val, "unixepoch") AS INTEGER)',
      day: 'CAST(strftime("%d", val, "unixepoch") AS INTEGER)',
      hour: 'CAST(strftime("%H", val, "unixepoch") AS INTEGER)',
      minute: 'CAST(strftime("%M", val, "unixepoch") AS INTEGER)',
      second: 'CAST(strftime("%S", val, "unixepoch") AS INTEGER)',
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
}
