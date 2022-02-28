import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test('parses CREATE INDEX statements', () {
    testStatement(
      'CREATE INDEX foo ON bar (baz, inga) WHERE TRUE',
      CreateIndexStatement(
        indexName: 'foo',
        on: TableReference('bar'),
        columns: [
          IndexedColumn(Reference(columnName: 'baz')),
          IndexedColumn(Reference(columnName: 'inga')),
        ],
        where: BooleanLiteral.withTrue(token(TokenType.$true)),
      ),
    );
  });

  test('with unique and IF NOT EXISTS', () {
    testStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS foo ON bar (baz);',
      CreateIndexStatement(
        unique: true,
        ifNotExists: true,
        indexName: 'foo',
        on: TableReference('bar'),
        columns: [
          IndexedColumn(Reference(columnName: 'baz')),
        ],
      ),
    );
  });

  test('can have ordering modes on index expressions', () {
    testStatement(
      'CREATE INDEX foo ON bar (a + b DESC);',
      CreateIndexStatement(
        indexName: 'foo',
        on: TableReference('bar'),
        columns: [
          IndexedColumn(
            BinaryExpression(
              Reference(columnName: 'a'),
              token(TokenType.plus),
              Reference(columnName: 'b'),
            ),
            OrderingMode.descending,
          ),
        ],
      ),
    );
  });

  test('can have collate expressions', () {
    testStatement(
      'CREATE INDEX foo ON bar (baz COLLATE RTRIM);',
      CreateIndexStatement(
        indexName: 'foo',
        on: TableReference('bar'),
        columns: [
          IndexedColumn(
            CollateExpression(
              inner: Reference(columnName: 'baz'),
              operator: token(TokenType.collate),
              collateFunction: identifier('RTRIM'),
            ),
          ),
        ],
      ),
    );
  });
}
