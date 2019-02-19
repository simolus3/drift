import 'package:sally/sally.dart';
import 'package:sally/src/runtime/components/component.dart';
import 'package:test_api/test_api.dart';

void main() {
  final expression = GeneratedIntColumn('col', false);

  final comparisons = {
    expression.isSmallerThan: '<',
    expression.isSmallerOrEqual: '<=',
    expression.isBiggerOrEqual: '>=',
    expression.isBiggerThan: '>'
  };

  final comparisonsVal = {
    expression.isSmallerThanValue: '<',
    expression.isSmallerOrEqualValue: '<=',
    expression.isBiggerOrEqualValue: '>=',
    expression.isBiggerThanValue: '>'
  };

  group('can compare with other expressions', () {
    final compare = GeneratedIntColumn('compare', false);

    comparisons.forEach((fn, value) {
      test('for operator $value', () {
        final ctx = GenerationContext(null);

        fn(compare).writeInto(ctx);

        expect(ctx.sql, 'col $value compare');
      });
    });
  });

  group('can compare with values', () {
    comparisonsVal.forEach((fn, value) {
      test('for operator $value', () {
        final ctx = GenerationContext(null);

        fn(12).writeInto(ctx);

        expect(ctx.sql, 'col $value ?');
        expect(ctx.boundVariables, [12]);
      });
    });
  });
}
