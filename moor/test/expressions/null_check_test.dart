import 'package:moor/moor.dart';
import 'package:moor/moor.dart' as moor;
import 'package:test/test.dart';

import '../data/utils/expect_equality.dart';
import '../data/utils/expect_generated.dart';

void main() {
  final innerExpression = GeneratedTextColumn('name', 'table', true);

  test('IS NULL expressions are generated', () {
    final oldFunction = moor.isNull(innerExpression);
    final extension = innerExpression.isNull();

    expect(oldFunction, generates('name IS NULL'));
    expect(extension, generates('name IS NULL'));

    expectEquals(oldFunction, extension);
  });

  test('IS NOT NULL expressions are generated', () {
    final oldFunction = moor.isNotNull(innerExpression);
    final extension = innerExpression.isNotNull();

    expect(oldFunction, generates('name IS NOT NULL'));
    expect(extension, generates('name IS NOT NULL'));

    expectEquals(oldFunction, extension);
  });

  test('generates COALESCE expressions', () {
    final expr = moor.coalesce([const Constant<int?>(null), const Constant(3)]);

    expect(expr, generates('COALESCE(NULL, 3)'));
  });
}
