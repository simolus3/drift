import 'package:drift/drift.dart';
import 'package:postgres/postgres.dart';
// ignore: implementation_imports
import 'package:postgres/src/text_codec.dart';
import 'package:uuid/uuid.dart';

class PostgresType<T extends Object> implements CustomSqlType<T> {
  static final _encoder = PostgresTextEncoder();

  final Type type;
  final String name;

  const PostgresType({required this.type, required this.name});

  @override
  String mapToSqlLiteral(T dartValue) {
    return '${_encoder.convert(dartValue)}::$name';
  }

  @override
  Object mapToSqlParameter(T dartValue) => TypedValue(type, dartValue);

  @override
  T read(Object fromSql) => fromSql as T;

  @override
  String sqlTypeName(GenerationContext context) => name;
}

class UuidType extends PostgresType<UuidValue> {
  const UuidType() : super(type: Type.uuid, name: 'uuid');

  @override
  String mapToSqlLiteral(UuidValue dartValue) {
    // UUIDs can't contain escape characters, so we don't check these values.
    return "'${dartValue.uuid}'";
  }

  @override
  Object mapToSqlParameter(UuidValue dartValue) {
    return TypedValue(Type.uuid, dartValue.uuid);
  }

  @override
  UuidValue read(Object fromSql) {
    return UuidValue(fromSql as String);
  }
}

// override because the text encoder doesn't properly encode PgPoint values
class PointType extends PostgresType<Point> {
  const PointType() : super(type: Type.point, name: 'point');

  @override
  String mapToSqlLiteral(Point dartValue) {
    return "'(${dartValue.latitude}, ${dartValue.longitude})'::point";
  }
}

class IntervalType extends PostgresType<Duration> {
  const IntervalType() : super(type: Type.interval, name: 'interval');

  @override
  String mapToSqlLiteral(Duration dartValue) {
    return "'${dartValue.inMicroseconds} microseconds'::interval";
  }
}

abstract interface class PgTimeValue {
  DateTime toDateTime();
}

class DateType<T extends PgTimeValue> extends PostgresType<T> {
  final T Function(DateTime) _fromDateTime;

  const DateType(
    Type type,
    String name,
    this._fromDateTime,
  ) : super(type: type, name: name);

  @override
  String mapToSqlLiteral(T dartValue) {
    return "${PostgresType._encoder.convert(dartValue.toDateTime())}::$name";
  }

  @override
  Object mapToSqlParameter(T dartValue) {
    return TypedValue(type, dartValue.toDateTime());
  }

  @override
  T read(Object fromSql) {
    return _fromDateTime(fromSql as DateTime);
  }
}
