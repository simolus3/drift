import 'package:drift3_preview/drift.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  final innerExpression = Expression.custom(
    'name',
    precedence: Precedence.primary,
  );

  test('IS NULL expressions are generated', () {
    final extension = innerExpression.isNull();
    expect(extension, generates('name IS NULL'));
  });

  test('IS NOT NULL expressions are generated', () {
    final extension = innerExpression.isNotNull();
    expect(extension, generates('name IS NOT NULL'));
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
    expect(Literal(3).nullIf(Literal(3)), generates('NULLIF(3,3)'));
  });
}
