import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../../test_utils/test_utils.dart';

void main() {
  const a = CustomExpression('a',
      customType: _NegatedIntType(), precedence: Precedence.primary);

  test('equals', () {
    expect(a.equals(123), generates('a = ?', [-123]));
  });

  test('is', () {
    expect(a.isValue(42), generates('a IS ?', [-42]));
    expect(a.isNotValue(42), generates('a IS NOT ?', [-42]));

    expect(a.isIn([1, 2, 3]), generates('a IN (?, ?, ?)', [-1, -2, -3]));
    expect(a.isNotIn([1, 2, 3]), generates('a NOT IN (?, ?, ?)', [-1, -2, -3]));
  });

  test('comparison', () {
    expect(a.isSmallerThanValue(42), generates('a < ?', [-42]));
    expect(a.isSmallerOrEqualValue(42), generates('a <= ?', [-42]));

    expect(a.isBiggerThanValue(42), generates('a > ?', [-42]));
    expect(a.isBiggerOrEqualValue(42), generates('a >= ?', [-42]));

    expect(
        a.isBetweenValues(12, 24), generates('a BETWEEN ? AND ?', [-12, -24]));
    expect(a.isBetweenValues(12, 24, not: true),
        generates('a NOT BETWEEN ? AND ?', [-12, -24]));
  });

  test('cast', () {
    expect(Variable.withInt(10).cast<int>(const _NegatedIntType()),
        generates('CAST(? AS custom_int)', [10]));
  });

  test('dartCast', () {
    final exp =
        Variable.withInt(10).dartCast<int>(customType: const _NegatedIntType());

    expect(exp, generates('?', [10]));
    expect(exp.driftSqlType, isA<_NegatedIntType>());
  });
}

class _NegatedIntType implements CustomSqlType<int> {
  const _NegatedIntType();

  @override
  String mapToSqlLiteral(int dartValue) {
    return '-$dartValue';
  }

  @override
  Object mapToSqlParameter(int dartValue) {
    return -dartValue;
  }

  @override
  int read(Object fromSql) {
    return -(fromSql as int);
  }

  @override
  String sqlTypeName(GenerationContext context) {
    return 'custom_int';
  }
}
