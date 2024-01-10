// #docregion duration
import 'package:drift/drift.dart';

class DurationType implements CustomSqlType<Duration> {
  const DurationType();

  @override
  String mapToSqlLiteral(Duration dartValue) {
    return "interval '${dartValue.inMicroseconds} microseconds'";
  }

  @override
  Object mapToSqlParameter(Duration dartValue) => dartValue;

  @override
  Duration read(Object fromSql) => fromSql as Duration;

  @override
  String sqlTypeName(GenerationContext context) => 'interval';
}
// #enddocregion duration

// #docregion fallback
class _FallbackDurationType implements CustomSqlType<Duration> {
  const _FallbackDurationType();

  @override
  String mapToSqlLiteral(Duration dartValue) {
    return dartValue.inMicroseconds.toString();
  }

  @override
  Object mapToSqlParameter(Duration dartValue) {
    return dartValue.inMicroseconds;
  }

  @override
  Duration read(Object fromSql) {
    return Duration(microseconds: fromSql as int);
  }

  @override
  String sqlTypeName(GenerationContext context) {
    return 'integer';
  }
}
// #enddocregion fallback

const durationType = DialectAwareSqlType<Duration>.via(
  fallback: _FallbackDurationType(),
  overrides: {
    SqlDialect.postgres: DurationType(),
  },
);
