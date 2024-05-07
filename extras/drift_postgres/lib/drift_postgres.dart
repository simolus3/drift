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
  static const CustomSqlType<pg.Interval> interval = IntervalType();

  /// The `date` type in Postgres.
  static const CustomSqlType<PgDate> date = DateType(
    pg.Type.date,
    'date',
    PgDate.fromDateTime,
  );

  /// The `timestamp with time zone` type in Postgres.
  static const CustomSqlType<PgDateTime> timestampWithTimezone = DateType(
    pg.Type.timestampWithTimezone,
    'timestamp with time zone',
    PgDateTime.new,
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

  /// A postgres array of [bool] values.
  static const CustomSqlType<List<bool>> booleanArray =
      ArrayType(type: pg.Type.booleanArray, name: 'boolean[]');

  /// A postgres array of [int] values, with each element being a 64bit integer.
  static const CustomSqlType<List<int>> bigIntArray =
      ArrayType(type: pg.Type.bigIntegerArray, name: 'int8[]');

  /// A postgres array of [String] values.
  static const CustomSqlType<List<String>> textArray =
      ArrayType(type: pg.Type.textArray, name: 'text[]');

  /// A postgres array of [double] values.
  static const CustomSqlType<List<double>> doubleArray =
      ArrayType(type: pg.Type.doubleArray, name: 'float8[]');

  /// A postgres array of JSON values, encoded as binary values.
  static const CustomSqlType<List<Object?>> jsonbArray =
      ArrayType(type: pg.Type.jsonbArray, name: 'jsonb[]');
}

/// A wrapper for values with the Postgres `timestamp without timezone` and
/// `timestamp with timezone` types.
///
/// We can't use [DateTime] directly because drift expects to store them as
/// unix timestamp or text.
final class PgDateTime implements PgTimeValue, Comparable<PgDateTime> {
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

  @override
  int compareTo(PgDateTime other) {
    return dateTime.compareTo(other.dateTime);
  }
}

/// A wrapper for the Postgres `date` type, which stores dates (year, month,
/// days).
final class PgDate implements PgTimeValue, Comparable<PgDate> {
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

  @override
  int compareTo(PgDate other) {
    return _dateTime.compareTo(other._dateTime);
  }
}

/// Calls the `gen_random_uuid` function in postgres.
Expression<UuidValue> genRandomUuid() {
  return FunctionCallExpression('gen_random_uuid', []);
}
