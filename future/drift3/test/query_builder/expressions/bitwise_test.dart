import 'package:drift3_preview/drift.dart';
import 'package:test/test.dart';

import '../../test_utils/matchers.dart';

void main() {
  group('int', () {
    final a = Expression<int>.custom('a', precedence: Precedence.primary);
    final b = Expression<int>.custom('b', precedence: Precedence.primary);

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
    final a = Expression<BigInt>.custom('a', precedence: Precedence.primary);
    final b = Expression<BigInt>.custom('b', precedence: Precedence.primary);

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
