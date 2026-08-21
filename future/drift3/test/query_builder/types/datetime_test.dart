import 'package:drift3_preview/drift.dart';
import 'package:drift_sqlite/drift_sqlite.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  final nullable = TableColumn<DateTime>(
    name: 'name',
    sqlType: BuiltinDriftType.dateTime,
  );
  final nonNull = TableColumn<DateTime>(
    name: 'name',
    sqlType: BuiltinDriftType.dateTime,
    constraints: () => const [ColumnNotNullConstraint()],
  );

  test('should write column definition', () {
    final generatedAsText = SqliteDialect.withOptions().createCompiler()
      ..addTableColumnDefinition(nonNull)
      ..statement.comma()
      ..addTableColumnDefinition(nullable);

    final generatedAsTimestamp =
        SqliteDialect.withOptions(
            options: SqliteOptions(storeDateTimesAsText: false),
          ).createCompiler()
          ..addTableColumnDefinition(nonNull)
          ..statement.comma()
          ..addTableColumnDefinition(nullable);

    expect(
      generatedAsText.statement.buffer.toString(),
      '"name" TEXT NOT NULL,"name" TEXT',
    );
    expect(
      generatedAsTimestamp.statement.buffer.toString(),
      '"name" INTEGER NOT NULL,"name" INTEGER',
    );
  });

  group('mapping datetime values', () {
    group('from dart to sql', () {
      final local = DateTime(2022, 07, 21, 22, 53, 12, 888, 999);
      final utc = DateTime.utc(2022, 07, 21, 22, 53, 12, 888, 999);

      test('as unix timestamp', () {
        const dialect = SqliteDialect.withOptions(
          options: SqliteOptions(storeDateTimesAsText: false),
        );

        expect(
          Variable(local),
          generatesWithDialect(
            '?1',
            dialect: dialect,
            variables: [local.millisecondsSinceEpoch ~/ 1000],
          ),
        );
        expect(
          Variable(utc),
          generatesWithDialect('?1', dialect: dialect, variables: [1658443992]),
        );

        expect(
          Literal(local),
          generatesWithDialect(
            '${local.millisecondsSinceEpoch ~/ 1000}',
            dialect: dialect,
          ),
        );
        expect(
          Literal(utc),
          generatesWithDialect('1658443992', dialect: dialect),
        );
      });

      test(
        'as text',
        () {
          const dialect = SqliteDialect.withOptions(
            options: SqliteOptions(storeDateTimesAsText: true),
          );

          expect(
            Variable<DateTime>(_MockDateTime(local, const Duration(hours: 1))),
            generatesWithDialect(
              '?1',
              variables: ['2022-07-21T22:53:12.888999 +01:00'],
              dialect: dialect,
            ),
          );
          expect(
            Variable<DateTime>(
              _MockDateTime(local, const Duration(hours: 1, minutes: 12)),
            ),
            generatesWithDialect(
              '?1',
              variables: ['2022-07-21T22:53:12.888999 +01:12'],
              dialect: dialect,
            ),
          );
          expect(
            Variable<DateTime>(
              _MockDateTime(local, -const Duration(hours: 1, minutes: 29)),
            ),
            generatesWithDialect(
              '?1',
              variables: ['2022-07-21T22:53:12.888999 -01:29'],
              dialect: dialect,
            ),
          );

          expect(
            Variable(utc),
            generatesWithDialect(
              '?1',
              variables: ['2022-07-21T22:53:12.888999Z'],
              dialect: dialect,
            ),
          );

          expect(
            Literal<DateTime>(_MockDateTime(local, const Duration(hours: 1))),
            generatesWithDialect(
              "'2022-07-21T22:53:12.888999 +01:00'",
              dialect: dialect,
            ),
          );
          expect(
            Literal(utc),
            generatesWithDialect(
              "'2022-07-21T22:53:12.888999Z'",
              dialect: dialect,
            ),
          );
        },
        onPlatform: const {
          'browser': Skip('Assumes DateTimes using int64 timestamps'),
        },
      );

      test('as text throws if UTC offset is not in minutes', () {
        // Writing date times with an UTC offset that isn't a whole minute
        // is not supported and should throw.
        const dialect = SqliteDialect.withOptions();

        expect(() {
          dialect.dateTimeType.sqlParameter(
            _MockDateTime(local, const Duration(seconds: 30)),
          );
        }, throwsArgumentError);

        expect(() {
          dialect.dateTimeType.sqlLiteral(
            _MockDateTime(local, const Duration(seconds: 30)),
          );
        }, throwsArgumentError);
      });
    });

    group('from sql to dart', () {
      test('as unix timestamp', () {
        const dialect = SqliteDialect.withOptions(
          options: SqliteOptions(storeDateTimesAsText: false),
        );

        expect(
          BuiltinDriftType.dateTime.resolveIn(dialect).dartValue(1658443992),
          DateTime.utc(2022, 07, 21, 22, 53, 12).toLocal(),
        );
      });

      test('as text', () {
        const dialect = SqliteDialect.withOptions(
          options: SqliteOptions(storeDateTimesAsText: true),
        );

        expect(
          BuiltinDriftType.dateTime
              .resolveIn(dialect)
              .dartValue('2022-07-21T22:53:12Z'),
          DateTime.utc(2022, 07, 21, 22, 53, 12),
        );

        expect(
          BuiltinDriftType.dateTime
              .resolveIn(dialect)
              .dartValue('2022-07-21T22:53:12 -03:00'),
          DateTime.utc(
            2022,
            07,
            21,
            22,
            53,
            12,
          ).add(const Duration(hours: 3)).toLocal(),
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
