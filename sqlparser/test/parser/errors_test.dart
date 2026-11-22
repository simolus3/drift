import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/utils/ast_equality.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test('WITH without following statement', () {
    expectError('WITH foo AS (SELECT * FROM bar)', [
      isParsingError(message: contains('to follow this WITH clause')),
    ]);
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
      expectError('SELECT 1, replace(a, b, c);', [
        isParsingError(
          message: contains('Did you mean to call a function?'),
          span: 'replace',
        ),
      ]);
    });

    test('as identifiers', () {
      expectError('SELECT * FROM foo WHERE group;', [
        isParsingError(
          message: contains('Did you mean to use it as a column?'),
          span: 'group',
        ),
      ]);

      expectError('CREATE TABLE x (table TEXT NOT NULL, foo INTEGER);', [
        isParsingError(
          message:
              'Expected a column name (got keyword TABLE, try wrapping it in double quotes to escape it).',
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

  test('missing result columns', () {
    final parsed = SqlEngine().parse(
      ParserEntrypoint.statement,
      'SELECT   FROM users;',
    );

    enforceEqual(
      parsed.rootNode,
      SelectStatement(columns: [], from: TableReference('users')),
    );
    expect(parsed.errors, [
      isParsingError(message: 'Expected a result column here.', span: 'FROM'),
    ]);
  });

  test('cast syntax errors', () {
    // Part of https://github.com/simolus3/drift/issues/3911, we used to crash.
    expectError("SELECT CAST(1 AS 'text')", [
      isParsingError(
        message: contains('closing parenthesis here'),
        span: "'text'",
      ),
    ]);
  });
}

void expectError(String sql, errorsMatcher) {
  final parsed = SqlEngine().parse(ParserEntrypoint.statement, sql);

  expect(parsed.errors, errorsMatcher);
}
