/// PostgreSQL backend for drift.
///
/// For more information on how to use this package, see
/// https://drift.simonbinder.eu/docs/platforms/postgres/.
library drift.postgres;

import 'package:drift/drift.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:uuid/uuid.dart';

import 'src/types.dart';

export 'src/pg_database.dart';
export 'package:uuid/uuid_value.dart' show UuidValue;

/// Type for columns storing [UuidValue]s.
typedef UuidColumn = Column<UuidValue>;

/// Type for columns storing [Duration]s as intervals.
typedef IntervalColumn = Column<Duration>;

/// Type for columns storing JSON structures.
typedef JsonColumn = Column<Object>;

/// Type for columns storing [PgPoint]s.
typedef PointColumn = Column<pg.Point>;

/// Type for columns storing dates directly as ([PgDateTime]).
typedef TimestampColumn = Column<PgDateTime>;

/// Type for columns storing dates directly as ([PgDate]).
typedef PgDateColumn = Column<PgDate>;

/// Provides [custom types](https://drift.simonbinder.eu/docs/sql-api/types/)
/// to enable the use of Postgres-specific types in drift databases.
final class PgTypes {
  PgTypes._();

  /// The `UUID` type in Postgres.
  static const CustomSqlType<UuidValue> uuid = UuidType();

  /// The `interval` type in Postgres.
  static const CustomSqlType<Duration> interval = IntervalType();

  /// The `date` type in Postgres.
  static const CustomSqlType<PgDate> date = DateType(
    pg.Type.date,
    'date',
    PgDate.fromDateTime,
  );

  /// The `timestamp without time zone` type in Postgres.
  static const CustomSqlType<PgDateTime> timestampNoTimezone = DateType(
    pg.Type.timestampWithoutTimezone,
    'timestamp without time zone',
    PgDateTime.new,
  );

  /// The `json` type in Postgres.
  static const CustomSqlType<Object> json =
      PostgresType(type: pg.Type.json, name: 'json');

  /// The `jsonb` type in Postgres.
  static const CustomSqlType<Object> jsonb =
      PostgresType(type: pg.Type.json, name: 'jsonb');

  /// The `point` type in Postgres.
  static const CustomSqlType<pg.Point> point = PointType();
}

/// A wrapper for values with the Postgres `timestamp without timezone` and
/// `timestamp with timezone` types.
///
/// We can't use [DateTime] directly because drift expects to store them as
/// unix timestamp or text.
final class PgDateTime implements PgTimeValue {
  final DateTime dateTime;

  PgDateTime(this.dateTime);

  @override
  int get hashCode => dateTime.hashCode;

  @override
  bool operator ==(Object other) {
    return other is PgDateTime && other.dateTime == dateTime;
  }

  @override
  DateTime toDateTime() => dateTime;

  @override
  String toString() => dateTime.toString();
}

/// A wrapper for the Postgres `date` type, which stores dates (year, month,
/// days).
final class PgDate implements PgTimeValue {
  final int year, month, day;
  final DateTime _dateTime;

  PgDate({required this.year, required this.month, required this.day})
      : _dateTime = DateTime(year, month, day);

  PgDate.fromDateTime(DateTime dateTime)
      : _dateTime = dateTime,
        year = dateTime.year,
        month = dateTime.month,
        day = dateTime.day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  bool operator ==(Object other) {
    return other is PgDate &&
        other.year == year &&
        other.month == month &&
        other.day == day;
  }

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  @override
  DateTime toDateTime() {
    return _dateTime;
  }
}

/// Calls the `gen_random_uuid` function in postgres.
Expression<UuidValue> genRandomUuid() {
  return FunctionCallExpression('gen_random_uuid', []);
}
