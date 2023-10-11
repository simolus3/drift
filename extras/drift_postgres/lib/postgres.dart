/// PostgreSQL
@experimental
library drift.postgres;

import 'package:drift/drift.dart';
import 'package:meta/meta.dart';
import 'package:postgres/postgres_v3_experimental.dart';
import 'package:uuid/uuid.dart';

import 'src/types.dart';

export 'src/pg_database.dart';
export 'package:uuid/uuid_value.dart' show UuidValue;

typedef UuidColumn = Column<UuidValue>;
typedef IntervalColumn = Column<Duration>;
typedef JsonColumn = Column<Object>;
typedef PointColumn = Column<PgPoint>;
typedef TimestampColumn = Column<PgDateTime>;
typedef PgDateColumn = Column<PgDate>;

final class PgTypes {
  PgTypes._();

  static const CustomSqlType<UuidValue> uuid = UuidType();
  static const CustomSqlType<Duration> interval = IntervalType();
  static const CustomSqlType<PgDate> date = DateType(
    PgDataType.date,
    'date',
    PgDate.fromDateTime,
  );
  static const CustomSqlType<PgDateTime> timestampNoTimezone = DateType(
    PgDataType.timestampWithoutTimezone,
    'timestamp without time zone',
    PgDateTime.new,
  );
  static const CustomSqlType<Object> json =
      PostgresType(type: PgDataType.json, name: 'json');
  static const CustomSqlType<Object> jsonb =
      PostgresType(type: PgDataType.json, name: 'jsonb');
  static const CustomSqlType<PgPoint> point = PointType();
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
