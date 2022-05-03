import 'package:drift_core/drift_core.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  final expression = Expression<int>.sql('col', precedence: Precedence.primary);

  group('can compare with other expressions', () {
    final compare =
        Expression<int>.sql('compare', precedence: Precedence.primary);

    final comparisons = {
      expression.isSmallerThan: '<',
      expression.isSmallerOrEqual: '<=',
      expression.isBiggerOrEqual: '>=',
      expression.isBiggerThan: '>'
    };

    comparisons.forEach((fn, value) {
      test('for operator $value', () {
        expect(fn(compare), generates('col $value compare'));
      });
    });
  });

  test('between', () {
    final low = Expression<int>.sql('low', precedence: Precedence.primary);
    final high = Expression<int>.sql('high', precedence: Precedence.primary);

    expect(
        expression.isBetween(low, high), generates('col BETWEEN low AND high'));
    expect(expression.isBetween(low, high, not: true),
        generates('col NOT BETWEEN low AND high'));
  });
}
