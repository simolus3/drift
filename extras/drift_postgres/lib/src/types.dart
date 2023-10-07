import 'package:drift/drift.dart';
import 'package:postgres/postgres_v3_experimental.dart';
// ignore: implementation_imports
import 'package:postgres/src/text_codec.dart';
import 'package:uuid/uuid.dart';

class PostgresType<T extends Object> implements CustomSqlType<T> {
  static final _encoder = PostgresTextEncoder();

  final PgDataType type;
  final String name;

  const PostgresType({required this.type, required this.name});

  @override
  String mapToSqlLiteral(T dartValue) {
    return '${_encoder.convert(dartValue)}::$name';
  }

  @override
  Object mapToSqlParameter(T dartValue) => PgTypedParameter(type, dartValue);

  @override
  T read(Object fromSql) => fromSql as T;

  @override
  String sqlTypeName(GenerationContext context) => name;
}

class UuidType extends PostgresType<UuidValue> {
  const UuidType() : super(type: PgDataType.uuid, name: 'uuid');

  @override
  String mapToSqlLiteral(UuidValue dartValue) {
    // UUIDs can't contain escape characters, so we don't check these values.
    return "'${dartValue.uuid}'";
  }

  @override
  Object mapToSqlParameter(UuidValue dartValue) {
    return PgTypedParameter(PgDataType.uuid, dartValue.uuid);
  }

  @override
  UuidValue read(Object fromSql) {
    return UuidValue(fromSql as String);
  }
}

// override because the text encoder doesn't properly encode PgPoint values
class PointType extends PostgresType<PgPoint> {
  const PointType() : super(type: PgDataType.point, name: 'point');

  @override
  String mapToSqlLiteral(PgPoint dartValue) {
    return "'(${dartValue.latitude}, ${dartValue.longitude})'::point";
  }
}

class IntervalType extends PostgresType<Duration> {
  const IntervalType() : super(type: PgDataType.interval, name: 'interval');

  @override
  String mapToSqlLiteral(Duration dartValue) {
    return "'${dartValue.inMicroseconds} microseconds'::interval";
  }
}
