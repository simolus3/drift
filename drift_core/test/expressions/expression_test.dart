import 'package:drift_core/drift_core.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  test('in', () {
    expect(
      Expression<int>.sql('a', precedence: Precedence.primary).isIn([1, 2, 3]),
      generates('a IN (?,?,?)', [1, 2, 3]),
    );
  });

  group('booleans', () {
    final a = Expression<bool>.sql('a', precedence: Precedence.primary);
    final b = Expression<bool>.sql('b', precedence: Precedence.primary);

    test('and', () {
      expect(a & b, generates('a AND b'));
    });

    test('or', () {
      expect(a | b, generates('a OR b'));
    });

    test('not', () {
      expect(not(a), generates('NOT a'));
    });

    test('combination and precedence', () {
      expect(a & (b | a), generates('a AND (b OR a)'));
    });
  });
}
