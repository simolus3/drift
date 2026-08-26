// ignore: implementation_imports
import 'package:drift/src/drift3_preview/drift.dart';

import 'package:postgres/postgres.dart' as pg;
// ignore: implementation_imports
import 'package:postgres/src/types/text_codec.dart';
import 'package:uuid/uuid_value.dart';

/// A typed value read from a Postgres result.
final class PostgresDatabaseValue {
  /// The column from which this value has been read.
  final pg.ResultSchemaColumn column;

  /// The raw value, decoded by the `postgres` package.
  final Object? value;

  /// @nodoc
  PostgresDatabaseValue({required this.column, required this.value});
}

/// The supertype of all type implementations in `drift_postgres.
base class PhysicalPostgresType<T extends Object> extends PhysicalSqlType<T> {
  static final _encoder = PostgresTextEncoder();

  /// The postgres [pg.Type] corresponding to this drift type.
  final pg.Type postgresType;

  @override
  final String typeName;

  /// @nodoc
  const PhysicalPostgresType(this.postgresType, this.typeName);

  @override
  pg.TypedValue sqlParameter(T? value) {
    return pg.TypedValue(postgresType, value, isSqlNull: value == null);
  }

  @override
  String sqlLiteral(T value) {
    return '${_encoder.convert(value)}::$typeName';
  }

  @override
  T dartValue(Object databaseValue) {
    return (databaseValue as PostgresDatabaseValue).value as T;
  }
}

/// The `uuid` type in Postgres, mapping to [UuidValue]s for drift.
final class UuidType extends PhysicalPostgresType<UuidValue> {
  /// @nodoc
  const UuidType() : super(pg.Type.uuid, 'uuid');

  @override
  String sqlLiteral(UuidValue value) {
    // UUIDs can't contain escape characters, so we don't check these values.
    return "'${value.uuid}'";
  }

  @override
  pg.TypedValue<Object> sqlParameter(UuidValue? value) {
    return pg.TypedValue(postgresType, value?.uuid, isSqlNull: value == null);
  }

  @override
  UuidValue dartValue(Object databaseValue) {
    return UuidValue.fromString(databaseValue as String);
  }
}

/// The `point` type in Postgres.
// override because the text encoder doesn't properly encode PgPoint values
final class PointType extends PhysicalPostgresType<pg.Point> {
  /// @nodoc
  const PointType() : super(pg.Type.point, 'point');

  @override
  String sqlLiteral(value) {
    return "'(${value.latitude}, ${value.longitude})'::point";
  }
}

/// A generic `interval` type in Postgres.
final class IntervalType extends PhysicalPostgresType<pg.Interval> {
  /// @nodoc
  const IntervalType() : super(pg.Type.interval, 'interval');

  @override
  String sqlLiteral(pg.Interval value) {
    return "'$value'::interval";
  }
}

/// Common superinterface for postgres time values.
abstract interface class PgTimeValue {
  /// Maps this postgres type value into a Dart [DateTime].
  DateTime toDateTime();
}

/// A type for Postgres datetime types.
final class DateType<T extends PgTimeValue> extends PhysicalPostgresType<T> {
  final T Function(DateTime) _fromDateTime;

  /// @nodoc
  const DateType(super.postgresType, super.typeName, this._fromDateTime);

  @override
  String sqlLiteral(T value) {
    return "${PhysicalPostgresType._encoder.convert(value.toDateTime())}::$typeName";
  }

  @override
  pg.TypedValue<Object> sqlParameter(T? value) {
    return pg.TypedValue(
      postgresType,
      value?.toDateTime(),
      isSqlNull: value == null,
    );
  }

  @override
  T dartValue(Object databaseValue) {
    return _fromDateTime(databaseValue as DateTime);
  }
}

/// An implementation for postgres array types.
final class ArrayType<T> extends PhysicalPostgresType<List<T>> {
  /// The inner postgres type.
  final PhysicalPostgresType? innerType;

  /// @nodoc
  const ArrayType(super.postgresType, super.typeName, {this.innerType});

  @override
  String sqlLiteral(List<T> value) {
    // This gives us the `{array, initializer}` syntax, but without the
    // surrounding quotes.
    final encoded = PhysicalPostgresType._encoder.convert(dartValue);
    final asStringLiteral = PhysicalPostgresType._encoder.convert(
      encoded,
      escapeStrings: true,
    );

    return '$asStringLiteral::$typeName';
  }
}

/// A type storing 64-bit values as [BigInt]s in Dart.
final class DartBigIntType extends PhysicalPostgresType<BigInt> {
  /// Implementation for drift's `int64` type.
  const DartBigIntType() : super(pg.Type.bigInteger, 'bigint');

  @override
  BigInt dartValue(Object databaseValue) {
    return BigInt.from(databaseValue as int);
  }

  @override
  pg.TypedValue<Object> sqlParameter(BigInt? value) {
    return pg.TypedValue(
      postgresType,
      value?.toInt(),
      isSqlNull: value == null,
    );
  }
}
