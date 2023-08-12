import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test('WITH without following statement', () {
    expectError('WITH foo AS (SELECT * FROM bar)',
        [isParsingError(message: contains('to follow this WITH clause'))]);
  });

  test('CREATE without following statement', () {
    expectError('CREATE', [
      isParsingError(message: contains('after the CREATE keyword')),
    ]);

    expectError('create from table_name', [
      isParsingError(message: contains('after the CREATE keyword')),
    ]);
  });

  group('when using keywords', () {
    test('for function calls', () {
      expectError('SELECT replace(a, b, c);', [
        isParsingError(
          message: contains('Did you mean to call a function?'),
          span: 'replace',
        ),
      ]);
    });

    test('as identifiers', () {
      expectError('SELECT group FROM foo;', [
        isParsingError(
          message: contains('Did you mean to use it as a column?'),
          span: 'group',
        ),
      ]);

      expectError('CREATE TABLE x (table TEXT NOT NULL, foo INTEGER);', [
        isParsingError(
          message: 'Expected a column name (got keyword TABLE)',
          span: 'table',
        ),
      ]);
    });

    test('recovers from invalid comma after table reference', () {
      expectError('SELECT * FROM table_name,', [
        isParsingError(
          message: 'Expected a table name or a nested select statement',
        ),
      ]);
    });
  });
}

void expectError(String sql, errorsMatcher) {
  final parsed = SqlEngine().parse(sql);

  expect(parsed.errors, errorsMatcher);
}
