//@dart=2.9
import 'package:moor/moor.dart';
import 'package:test/test.dart';

import '../data/tables/todos.dart';
import '../data/utils/expect_equality.dart';

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
        final ctx = GenerationContext.fromDb(db);

        fn(compare).writeInto(ctx);

        expect(ctx.sql, 'col $value compare');

        expectEquals(fn(compare), fn(compare));
      });
    });
  });

  group('can compare with values', () {
    comparisonsVal.forEach((fn, value) {
      test('for operator $value', () {
        final ctx = GenerationContext.fromDb(db);

        fn(12).writeInto(ctx);

        expect(ctx.sql, 'col $value ?');
        expect(ctx.boundVariables, [12]);
      });
    });
  });

  group('between', () {
    test('other expressions', () {
      final low = GeneratedIntColumn('low', null, false);
      final high = GeneratedIntColumn('high', null, false);

      final ctx = GenerationContext.fromDb(db);
      expression.isBetween(low, high).writeInto(ctx);

      expect(ctx.sql, 'col BETWEEN low AND high');
    });

    test('values', () {
      final ctx = GenerationContext.fromDb(db);
      expression.isBetweenValues(3, 15).writeInto(ctx);

      expect(ctx.sql, 'col BETWEEN ? AND ?');
      expect(ctx.boundVariables, [3, 15]);
    });
  });
}
