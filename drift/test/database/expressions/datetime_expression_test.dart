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
  (d) => d.date: "DATE(val, 'unixepoch')",
  (d) => d.datetime: "DATETIME(val, 'unixepoch')",
  (d) => d.time: "TIME(val, 'unixepoch')",
  (d) => d.unixepoch: 'val',
  (d) => d.julianday: "JULIANDAY(val, 'unixepoch')",
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
  const column =
      CustomExpression<DateTime>('val', precedence: Precedence.primary);

  for (final useText in [false, true]) {
    final desc = useText ? 'text' : 'timestamp';

    group('storing datetime values as $desc', () {
      final options = DriftDatabaseOptions(storeDateTimeAsText: useText);

      group('extracting information via top-level method', () {
        final expectedResults =
            useText ? _expectedResultsText : _expectedResultsTimestamp;

        expectedResults.forEach((key, value) {
          test('should extract field', () {
            expect(key(column), generatesWithOptions(value, options: options));
          });
        });
      });

      test('can cast datetimes to unix timestamps without rewriting', () {
        final expr = currentDateAndTime.unixepoch + const Constant(10);
        final expectedSql = useText
            ? 'UNIXEPOCH(CURRENT_TIMESTAMP) + 10'
            : 'CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER) + 10';

        expect(expr, generatesWithOptions(expectedSql, options: options));
      });

      test('plus and minus durations', () {
        final expr = currentDateAndTime +
            const Duration(days: 3) -
            const Duration(seconds: 5);

        if (useText) {
          expect(
            expr,
            generatesWithOptions(
              "datetime(datetime(CURRENT_TIMESTAMP, '259200.0 seconds'), "
              "'-5.0 seconds')",
              options: options,
            ),
          );
        } else {
          expect(
            expr,
            generates(
                'CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER) + ? - ?',
                [259200, 5]),
          );
        }
      });

      test('can compare', () {
        final left = Variable(DateTime.utc(2022, 07, 22));
        final right = Variable(DateTime.utc(2022, 07, 23));

        if (useText) {
          expect(
              left.isSmallerThan(right),
              generatesWithOptions(
                'JULIANDAY(?) < JULIANDAY(?)',
                options: options,
                variables: [
                  '2022-07-22T00:00:00.000Z',
                  '2022-07-23T00:00:00.000Z'
                ],
              ));
        } else {
          expect(
              left.isSmallerThan(right),
              generatesWithOptions(
                '? < ?',
                options: options,
                variables: [1658448000, 1658534400],
              ));
        }
      });
    });
  }
}
