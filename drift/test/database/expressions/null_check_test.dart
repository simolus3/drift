import 'package:drift/drift.dart';
import 'package:drift/drift.dart' as drift;
import 'package:test/test.dart';

import '../../test_utils/test_utils.dart';

void main() {
  const innerExpression =
      CustomExpression<int>('name', precedence: Precedence.primary);

  test('IS NULL expressions are generated', () {
    // ignore: deprecated_member_use_from_same_package
    final oldFunction = drift.isNull(innerExpression);
    final extension = innerExpression.isNull();

    expect(oldFunction, generates('name IS NULL'));
    expect(extension, generates('name IS NULL'));

    expectEquals(oldFunction, extension);
  });

  test('IS NOT NULL expressions are generated', () {
    // ignore: deprecated_member_use_from_same_package
    final oldFunction = drift.isNotNull(innerExpression);
    final extension = innerExpression.isNotNull();

    expect(oldFunction, generates('name IS NOT NULL'));
    expect(extension, generates('name IS NOT NULL'));

    expectEquals(oldFunction, extension);
  });

  test('generates COALESCE expressions', () {
    final expr = drift.coalesce([const Constant<int>(null), const Constant(3)]);

    expect(expr, generates('COALESCE(NULL, 3)'));
  });

  test('generates IFNULL expressions', () {
    expect(
      drift.ifNull<int>(const Constant<int>(null), Constant(3)),
      generates('IFNULL(NULL, 3)'),
    );
  });

  test('generates NULLIF expressions', () {
    expect(
      Constant(3).nullIf(Constant(3)),
      generates('NULLIF(3, 3)'),
    );
  });
}
