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
