import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../../test_utils/matchers.dart';

void main() {
  group('int', () {
    final a = CustomExpression<int>('a', precedence: Precedence.primary);
    final b = CustomExpression<int>('b', precedence: Precedence.primary);

    test('not', () {
      expect(~a, generates('~a'));
      expect(~(a + b), generates('~(a + b)'));
    });

    test('or', () {
      expect(a.bitwiseOr(b), generates('a | b'));
      expect((~a).bitwiseOr(b), generates('~a | b'));
      expect(~(a.bitwiseOr(b)), generates('~(a | b)'));
    });

    test('and', () {
      expect(a.bitwiseAnd(b), generates('a & b'));
      expect(-(a.bitwiseAnd(b)), generates('-(a & b)'));
    });
  });

  group('BigInt', () {
    final a = CustomExpression<BigInt>('a', precedence: Precedence.primary);
    final b = CustomExpression<BigInt>('b', precedence: Precedence.primary);

    test('not', () {
      expect(~a, generates('~a'));
      expect(~(a + b), generates('~(a + b)'));
    });

    test('or', () {
      expect(a.bitwiseOr(b), generates('a | b'));
      expect((~a).bitwiseOr(b), generates('~a | b'));
      expect(~(a.bitwiseOr(b)), generates('~(a | b)'));
    });

    test('and', () {
      expect(a.bitwiseAnd(b), generates('a & b'));
      expect(-(a.bitwiseAnd(b)), generates('-(a & b)'));
    });
  });
}
