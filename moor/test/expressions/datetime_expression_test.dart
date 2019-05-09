import 'package:moor/moor.dart';
import 'package:moor/src/runtime/components/component.dart';
import 'package:moor/src/runtime/expressions/expression.dart';
import 'package:test_api/test_api.dart';

typedef Expression<int, IntType> _Extractor(
    Expression<DateTime, DateTimeType> d);

/// Tests the top level [year], [month], ..., [second] methods
void main() {
  final expectedResults = <_Extractor, String>{
    year: 'CAST(strftime("%Y", val, "unixepoch") AS INTEGER)',
    month: 'CAST(strftime("%m", val, "unixepoch") AS INTEGER)',
    day: 'CAST(strftime("%d", val, "unixepoch") AS INTEGER)',
    hour: 'CAST(strftime("%H", val, "unixepoch") AS INTEGER)',
    minute: 'CAST(strftime("%M", val, "unixepoch") AS INTEGER)',
    second: 'CAST(strftime("%S", val, "unixepoch") AS INTEGER)',
  };
  final column = GeneratedDateTimeColumn('val', null, false);

  expectedResults.forEach((key, value) {
    test('should extract field', () {
      final ctx = GenerationContext(const SqlTypeSystem.withDefaults(), null);
      key(column).writeInto(ctx);

      expect(ctx.sql, value);
    });
  });
}
