import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../../test_utils/test_utils.dart';

void main() {
  final nullable = GeneratedColumn<DateTime>('name', 'table', true,
      type: DriftSqlType.dateTime);
  final nonNull = GeneratedColumn<DateTime>('name', 'table', false,
      type: DriftSqlType.dateTime);

  test('should write column definition', () {
    final nonNullQuery = stubContext();
    final nullableQuery = stubContext();
    nonNull.writeColumnDefinition(nonNullQuery);
    nullable.writeColumnDefinition(nullableQuery);

    expect(nullableQuery.sql, equals('name INTEGER NULL'));
    expect(nonNullQuery.sql, equals('name INTEGER NOT NULL'));
  });

  test('can compare', () {
    final ctx = stubContext();
    nonNull.isSmallerThan(currentDateAndTime).writeInto(ctx);

    expect(ctx.sql, "name < strftime('%s', CURRENT_TIMESTAMP)");
  });

  group('mapping datetime values', () {
    group('from dart to sql', () {
      final local = DateTime(2022, 07, 21, 22, 53, 12, 888, 999);
      final utc = DateTime.utc(2022, 07, 21, 22, 53, 12, 888, 999);

      test('as unix timestamp', () {
        expect(Variable(local),
            generates('?', [local.millisecondsSinceEpoch ~/ 1000]));
        expect(Variable(utc), generates('?', [1658443992]));

        expect(Constant(local),
            generates('${local.millisecondsSinceEpoch ~/ 1000}'));
        expect(Constant(utc), generates('1658443992'));
      });

      test('as text', () {
        const options = DriftDatabaseOptions(storeDateTimeAsText: true);

        expect(
          Variable(_MockDateTime(local, const Duration(hours: 1))),
          generatesWithOptions(
            '?',
            variables: ['2022-07-21T22:53:12.888999 +01:00'],
            options: options,
          ),
        );
        expect(
          Variable(_MockDateTime(local, const Duration(hours: 1, minutes: 12))),
          generatesWithOptions(
            '?',
            variables: ['2022-07-21T22:53:12.888999 +01:12'],
            options: options,
          ),
        );
        expect(
          Variable(
              _MockDateTime(local, -const Duration(hours: 1, minutes: 29))),
          generatesWithOptions(
            '?',
            variables: ['2022-07-21T22:53:12.888999 -01:29'],
            options: options,
          ),
        );

        expect(
          Variable(utc),
          generatesWithOptions(
            '?',
            variables: ['2022-07-21T22:53:12.888999Z'],
            options: options,
          ),
        );

        expect(
          Constant(_MockDateTime(local, const Duration(hours: 1))),
          generatesWithOptions(
            "'2022-07-21T22:53:12.888999 +01:00'",
            options: options,
          ),
        );
        expect(
          Constant(utc),
          generatesWithOptions("'2022-07-21T22:53:12.888999Z'",
              options: options),
        );

        // Writing date times with an UTC offset that isn't a whole minute
        // is not supported and should throw.
        expect(() {
          final context = stubContext(options: options);
          Variable(_MockDateTime(local, const Duration(seconds: 30)))
              .writeInto(context);
        }, throwsArgumentError);

        expect(() {
          final context = stubContext(options: options);
          Constant(_MockDateTime(local, const Duration(seconds: 30)))
              .writeInto(context);
        }, throwsArgumentError);
      });
    });

    group('from sql to dart', () {
      test('as unix timestamp', () {
        const types = SqlTypes(false);

        expect(types.read(DriftSqlType.dateTime, 1658443992),
            DateTime.utc(2022, 07, 21, 22, 53, 12).toLocal());
      });

      test('as text', () {
        const types = SqlTypes(true);

        expect(types.read(DriftSqlType.dateTime, '2022-07-21T22:53:12Z'),
            DateTime.utc(2022, 07, 21, 22, 53, 12));

        expect(
          types.read(DriftSqlType.dateTime, '2022-07-21T22:53:12 -03:00'),
          DateTime.utc(2022, 07, 21, 22, 53, 12)
              .add(const Duration(hours: 3))
              .toLocal(),
        );
      });
    });
  });
}

class _MockDateTime implements DateTime {
  final DateTime original;
  final Duration utcOffset;

  _MockDateTime(this.original, this.utcOffset) : assert(!original.isUtc);

  @override
  bool get isUtc => false;

  @override
  Duration get timeZoneOffset => utcOffset;

  @override
  String toIso8601String() {
    return original.toIso8601String();
  }

  @override
  String toString() {
    return '${original.toString()} with fake offset $utcOffset';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}
