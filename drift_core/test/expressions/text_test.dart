import 'package:drift_core/drift_core.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  group('like', () {
    final expr = Expression<String>.sql('left', precedence: Precedence.primary);

    test('with string literal pattern', () {
      expect(expr.like('foo%'), generates('left LIKE ?', ['foo%']));
      expect(expr.like('_foo%'), generates('left LIKE ?', ['_foo%']));
    });

    test('with dynamic expressions', () {
      expect(
          expr.likeExpr(
              Expression<String>.sql('other', precedence: Precedence.primary)),
          generates('left LIKE other'));
    });
  });

  test('upper and lower', () {
    final expr = sqlVar('foo');

    expect(expr.lower, generates('LOWER(?)', ['foo']));
    expect(expr.upper, generates('UPPER(?)', ['foo']));
  });
}
