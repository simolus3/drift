/// PostgreSQL backend for drift.
///
/// For more information on how to use this package, see
/// https://drift.simonbinder.eu/docs/platforms/postgres/.
library;

// ignore_for_file: experimental_member_use

// ignore: implementation_imports
import 'package:drift/src/drift3_preview/drift.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:uuid/uuid.dart';

import 'array_access_expression.dart';
import 'type.dart';

export 'package:uuid/uuid_value.dart' show UuidValue;
export 'dialect.dart' show PostgresDialect;

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
  static const PhysicalSqlType<UuidValue> uuid = UuidType();

  /// The `interval` type in Postgres.
  static const PhysicalSqlType<pg.Interval> interval = IntervalType();

  /// The `date` type in Postgres.
  static const PhysicalSqlType<PgDate> date = DateType(
    pg.Type.date,
    'date',
    PgDate.fromDateTime,
  );

  /// The `timestamp with time zone` type in Postgres.
  static const PhysicalSqlType<PgDateTime> timestampWithTimezone = DateType(
    pg.Type.timestampWithTimezone,
    'timestamp with time zone',
    PgDateTime.new,
  );

  /// The `timestamp without time zone` type in Postgres.
  static const PhysicalSqlType<PgDateTime> timestampNoTimezone = DateType(
    pg.Type.timestampWithoutTimezone,
    'timestamp without time zone',
    PgDateTime.new,
  );

  /// The `point` type in Postgres.
  static const PhysicalSqlType<pg.Point> point = PointType();

  /// A postgres array of [bool] values.
  static const PhysicalSqlType<List<bool>> booleanArray = ArrayType(
    pg.Type.booleanArray,
    'boolean[]',
  );

  /// A postgres array of [int] values, with each element being a 64bit integer.
  static const PhysicalSqlType<List<int>> bigIntArray = ArrayType(
    pg.Type.bigIntegerArray,
    'int8[]',
  );

  /// A postgres array of [String] values.
  static const PhysicalSqlType<List<String>> textArray = ArrayType(
    pg.Type.textArray,
    'text[]',
  );

  /// A postgres array of [double] values.
  static const PhysicalSqlType<List<double>> doubleArray = ArrayType(
    pg.Type.doubleArray,
    'float8[]',
  );

  /// A postgres array of JSON values, encoded as binary values.
  static const PhysicalSqlType<List<Object?>> jsonbArray = ArrayType(
    pg.Type.jsonbArray,
    'jsonb[]',
    innerType: PhysicalPostgresType(pg.Type.jsonb, 'jsonb'),
  );
}

/// A wrapper for values with the Postgres `timestamp without timezone` and
/// `timestamp with timezone` types.
///
/// We can't use [DateTime] directly because drift expects to store them as
/// unix timestamp or text.
final class PgDateTime implements PgTimeValue, Comparable<PgDateTime> {
  /// The underlying [DateTime] value.
  final DateTime dateTime;

  /// @nodoc
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

  /// @nodoc
  Object? toJson() {
    return toString();
  }
}

/// A wrapper for the Postgres `date` type, which stores dates (year, month,
/// days).
final class PgDate implements PgTimeValue, Comparable<PgDate> {
  /// The year, month and day components making up this date value.
  final int year, month, day;
  final DateTime _dateTime;

  /// @nodoc
  PgDate({required this.year, required this.month, required this.day})
    : _dateTime = DateTime(year, month, day);

  /// @nodoc
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

  /// @nodoc
  Object? toJson() {
    return toString();
  }
}

/// Calls the `gen_random_uuid` function in postgres.
Expression<UuidValue> genRandomUuid() {
  return FunctionCallExpression(
    'gen_random_uuid',
    [],
  ).dartCast(customType: PgTypes.uuid);
}

/// Calls the `NOW()` function in postgres.
Expression<PgDateTime> now() {
  return FunctionCallExpression(
    'NOW',
    [],
  ).dartCast(customType: PgTypes.timestampWithTimezone);
}

/// Exposes expression builders for array types in postgres.
extension ArrayExpressions<T extends Object> on Expression<List<T?>> {
  /// Returns an expression accessing the element at the given [index] from this
  /// array.
  ///
  /// To pass a Dart integer for [index], wrap it in a [Variable.withInt].
  /// Note that, by default, __Postgres uses a one-based starting index!__.
  ///
  /// See also: https://www.postgresql.org/docs/current/arrays.html#ARRAYS-ACCESSING
  Expression<T> operator [](Expression<int> index) {
    final inner = (sqlType as ArrayType<T?>).innerType;

    return ArrayAccessExpression(
      array: this,
      index: index,
      sqlType: inner as SqlType<T>,
    );
  }

  /// Returns an expression evaluating to the length of this array.
  Expression<int> get length {
    return FunctionCallExpression('array_length', [this, const Literal(1)]);
  }

  /// Concatenates `this` and the [other] array into a single array.
  Expression<List<T>> operator +(Expression<List<T>> other) {
    return (dartCast<String>() + other.dartCast()).dartCast(
      customType: sqlType as SqlType<List<T>>,
    );
  }
}
