import 'package:drift/dialect/sqlite.dart';
import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../../test_utils/test_utils.dart';

typedef _Extractor = Expression Function(Expression<DateTime> d);

final _expectedResultsTimestamp = <_Extractor, String>{
  (d) => d.year: "CAST(strftime('%Y', val, 'unixepoch') AS INTEGER)",
  (d) => d.month: "CAST(strftime('%m', val, 'unixepoch') AS INTEGER)",
  (d) => d.day: "CAST(strftime('%d', val, 'unixepoch') AS INTEGER)",
  (d) => d.hour: "CAST(strftime('%H', val, 'unixepoch') AS INTEGER)",
  (d) => d.minute: "CAST(strftime('%M', val, 'unixepoch') AS INTEGER)",
  (d) => d.second: "CAST(strftime('%S', val, 'unixepoch') AS INTEGER)",
  (d) => d.date: "DATE(val,'unixepoch')",
  (d) => d.datetime: "DATETIME(val,'unixepoch')",
  (d) => d.time: "TIME(val,'unixepoch')",
  (d) => d.unixepoch: 'val',
  (d) => d.julianday: "JULIANDAY(val,'unixepoch')",
};

final _expectedResultsText = <_Extractor, String>{
  (d) => d.year: "CAST(strftime('%Y', val) AS INTEGER)",
  (d) => d.month: "CAST(strftime('%m', val) AS INTEGER)",
  (d) => d.day: "CAST(strftime('%d', val) AS INTEGER)",
  (d) => d.hour: "CAST(strftime('%H', val) AS INTEGER)",
  (d) => d.minute: "CAST(strftime('%M', val) AS INTEGER)",
  (d) => d.second: "CAST(strftime('%S', val) AS INTEGER)",
  (d) => d.date: 'DATE(val)',
  (d) => d.datetime: 'DATETIME(val)',
  (d) => d.time: 'TIME(val)',
  (d) => d.unixepoch: 'UNIXEPOCH(val)',
  (d) => d.julianday: 'JULIANDAY(val)',
};

void main() {
  const column = Expression<DateTime>.custom(CustomComponent('val'),
      precedence: Precedence.primary);

  for (final useText in [false, true]) {
    final desc = useText ? 'text' : 'timestamp';

    group('storing datetime values as $desc', () {
      final dialect =
          SqliteDialect(options: SqliteOptions(storeDateTimesAsText: useText));

      group('extracting information via top-level method', () {
        final expectedResults =
            useText ? _expectedResultsText : _expectedResultsTimestamp;

        expectedResults.forEach((key, value) {
          test('should extract field', () {
            expect(key(column), generatesWithOptions(value, dialect: dialect));
            expectEquals(key(column), key(column));
          });
        });
      });

      test('can cast datetimes to unix timestamps without rewriting', () {
        final expr = currentDateAndTime.unixepoch + const Literal(10);
        final expectedSql = useText
            ? 'UNIXEPOCH(CURRENT_TIMESTAMP) + 10'
            : 'CAST(strftime(\'%s\',CURRENT_TIMESTAMP) AS INTEGER) + 10';

        expect(expr, generatesWithOptions(expectedSql, dialect: dialect));
      });

      test('plus and minus durations', () {
        final expr = currentDateAndTime +
            const Duration(days: 3) -
            const Duration(seconds: 5);

        if (useText) {
          expect(
            expr,
            anyOf(
              generatesWithOptions(
                "datetime(datetime(CURRENT_TIMESTAMP,'259200.0 seconds'),"
                "'-5.0 seconds')",
                dialect: dialect,
              ),
              // emits a whole number on the web which is fine too
              generatesWithOptions(
                "datetime(datetime(CURRENT_TIMESTAMP,'259200 seconds'),"
                "'-5 seconds')",
                dialect: dialect,
              ),
            ),
          );
        } else {
          expect(
            expr,
            generatesWithOptions(
              '(CAST(strftime(\'%s\',CURRENT_TIMESTAMP) AS INTEGER) + ?1) - ?2',
              variables: [259200, 5],
              dialect: dialect,
            ),
          );
        }
      });

      test('can compare', () {
        final left = Variable(DateTime.utc(2022, 07, 22));
        final right = Variable(DateTime.utc(2022, 07, 23));

        if (useText) {
          expect(
              left.isLessThan(right),
              generatesWithOptions(
                'julianday(?1) < julianday(?2)',
                dialect: dialect,
                variables: [
                  '2022-07-22T00:00:00.000Z',
                  '2022-07-23T00:00:00.000Z'
                ],
              ));
        } else {
          expect(
              left.isLessThan(right),
              generatesWithOptions(
                '?1 < ?2',
                dialect: dialect,
                variables: [1658448000, 1658534400],
              ));
        }
      });

      test('from unix epoch', () {
        expect(
          DateTimeExpressions.fromUnixEpoch(column.dartCast()),
          generatesWithOptions(
            useText ? "datetime(val,'unixepoch')" : 'val',
            dialect: dialect,
          ),
        );
      });
    });
  }
}
