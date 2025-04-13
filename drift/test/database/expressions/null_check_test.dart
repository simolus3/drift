import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../../test_utils/test_utils.dart';

void main() {
  const innerExpression = Expression<int>.customComponent(
      CustomComponent('name'),
      precedence: Precedence.primary);

  test('IS NULL expressions are generated', () {
    expect(innerExpression.isNull(), generates('name IS NULL'));
  });

  test('IS NOT NULL expressions are generated', () {
    expect(innerExpression.isNotNull(), generates('name IS NOT NULL'));
  });

  test('generates COALESCE expressions', () {
    final expr = coalesce([const Literal<int>(null), const Literal(3)]);

    expect(expr, generates('COALESCE(NULL,3)'));
  });

  test('generates IFNULL expressions', () {
    expect(
      ifNull<int>(const Literal<int>(null), Literal(3)),
      generates('IFNULL(NULL,3)'),
    );
  });

  test('generates NULLIF expressions', () {
    expect(
      Literal(3).nullIf(Literal(3)),
      generates('NULLIF(3,3)'),
    );
  });
}
