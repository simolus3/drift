import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../../test_utils/test_utils.dart';

void main() {
  const expression =
      CustomExpression<String>('col', precedence: Precedence.primary);

  test('generates like expressions', () {
    expect(expression.like('pattern'), generates('col LIKE ?', ['pattern']));
    expect(expression.likeExp(expression), generates('col LIKE col'));
  });

  test('generates regexp expressions', () {
    expect(
      expression.regexp('fo+'),
      generates('col REGEXP ?', ['fo+']),
    );
  });

  test('generates collate expressions', () {
    expect(expression.collate(Collate.binary), generates('col COLLATE BINARY'));
    expect(expression.collate(Collate.noCase), generates('col COLLATE NOCASE'));
    expect(expression.collate(Collate.rTrim), generates('col COLLATE RTRIM'));
    expect(expression.collate(const Collate('custom')),
        generates('col COLLATE custom'));
  });

  test('can use contains', () {
    expect(
        expression.contains('foo bar'), generates('col LIKE ?', ['%foo bar%']));
  });

  group('can use string functions', () {
    final tests = {
      expression.upper(): 'UPPER(col)',
      expression.lower(): 'LOWER(col)',
      expression.trim(): 'TRIM(col)',
      expression.trimLeft(): 'LTRIM(col)',
      expression.trimRight(): 'RTRIM(col)',
      expression.length: 'LENGTH(col)',
    };

    tests.forEach((expr, sql) {
      test(sql, () {
        expect(expr, generates(sql));
      });
    });
  });

  test('substr', () {
    expect(expression.substr(10), generates('SUBSTR(col, 10)'));
    expect(expression.substr(10, 2), generates('SUBSTR(col, 10, 2)'));
  });
}
