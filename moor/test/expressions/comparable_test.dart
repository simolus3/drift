import 'package:moor/moor.dart';
import 'package:moor/src/runtime/components/component.dart';
import 'package:test_api/test_api.dart';

import '../data/tables/todos.dart';

void main() {
  final expression = GeneratedIntColumn('col', null, false);
  final db = TodoDb(null);

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
    final compare = GeneratedIntColumn('compare', null, false);

    comparisons.forEach((fn, value) {
      test('for operator $value', () {
        final ctx = GenerationContext(db);

        fn(compare).writeInto(ctx);

        expect(ctx.sql, 'col $value compare');
      });
    });
  });

  group('can compare with values', () {
    comparisonsVal.forEach((fn, value) {
      test('for operator $value', () {
        final ctx = GenerationContext(db);

        fn(12).writeInto(ctx);

        expect(ctx.sql, 'col $value ?');
        expect(ctx.boundVariables, [12]);
      });
    });
  });
}
