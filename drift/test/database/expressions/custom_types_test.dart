import 'package:drift/dialect/postgres.dart';
import 'package:drift/dialect/sqlite.dart';
import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../../test_utils/test_utils.dart';

void main() {
  final a = Expression.custom('a',
      customType: _NegatedIntType(), precedence: Precedence.primary);

  test('equals', () {
    expect(a.equals(123), generates('a = ?1', [-123]));
  });

  test('is', () {
    expect(a.isValue(42), generates('a IS ?1', [-42]));
    expect(a.isNotValue(42), generates('a IS NOT ?1', [-42]));

    expect(a.isIn([1, 2, 3]), generates('a IN (?1,?2,?3)', [-1, -2, -3]));
    expect(
        a.isNotIn([1, 2, 3]), generates('a NOT IN (?1,?2,?3)', [-1, -2, -3]));
  });

  test('comparison', () {
    expect(a.isLessThanValue(42), generates('a < ?1', [-42]));
    expect(a.isLessOrEqualValue(42), generates('a <= ?1', [-42]));

    expect(a.isGreaterThanValue(42), generates('a > ?1', [-42]));
    expect(a.isGreaterOrEqualValue(42), generates('a >= ?1', [-42]));

    expect(a.isBetweenValues(12, 24),
        generates('a BETWEEN ?1 AND ?2', [-12, -24]));
    expect(a.isBetweenValues(12, 24, not: true),
        generates('a NOT BETWEEN ?1 AND ?2', [-12, -24]));
  });

  test('cast', () {
    expect(Variable.withInt(10).cast<int>(const _NegatedIntType()),
        generates('CAST(?1 AS custom_int)', [10]));
  });

  test('dartCast', () {
    final exp =
        Variable.withInt(10).dartCast<int>(customType: const _NegatedIntType());

    expect(exp, generates('?1', [10]));
    expect(exp.resolveType(const SqliteDialect()), isA<_NegatedIntType>());
  });

  test('also supports dialect-aware types', () {
    final b = Expression.custom(
      'b',
      customType: SqlType<int>.dialectSpecific(
        fallback: _NegatedIntType(),
        overrides: {KnownSqlDialect.postgres: BuiltinDriftType.int},
      ),
      precedence: Precedence.primary,
    );

    expect(b.equals(3), generates('b = ?1', [-3]));
    expect(
        b.equals(3),
        generatesWithOptions('b = \$1',
            variables: [3], dialect: const PostgresDialect()));
  });
}

final class _NegatedIntType implements SqlType<int> {
  const _NegatedIntType();

  @override
  int dartValue(DriftDialect dialect, Object databaseValue) {
    return -(databaseValue as int);
  }

  @override
  String sqlLiteral(DriftDialect dialect, int value) {
    return '-$value';
  }

  @override
  Object sqlParameter(DriftDialect dialect, int value) {
    return -value;
  }

  @override
  String typeName(DriftDialect dialect) {
    return 'custom_int';
  }
}
