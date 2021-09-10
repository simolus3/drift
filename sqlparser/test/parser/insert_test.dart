import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test('parses insert statements', () {
    testStatement(
      'INSERT OR REPLACE INTO tbl (a, b, c) VALUES (d, e, f)',
      InsertStatement(
        mode: InsertMode.insertOrReplace,
        table: TableReference('tbl'),
        targetColumns: [
          Reference(columnName: 'a'),
          Reference(columnName: 'b'),
          Reference(columnName: 'c'),
        ],
        source: ValuesSource([
          Tuple(expressions: [
            Reference(columnName: 'd'),
            Reference(columnName: 'e'),
            Reference(columnName: 'f'),
          ]),
        ]),
      ),
    );
  });

  test('insert statement with default values', () {
    testStatement(
      'INSERT INTO tbl DEFAULT VALUES',
      InsertStatement(
        mode: InsertMode.insert,
        table: TableReference('tbl'),
        targetColumns: const [],
        source: DefaultValues(),
      ),
    );
  });

  test('insert statement with select as source', () {
    testStatement(
      'REPLACE INTO tbl SELECT * FROM tbl',
      InsertStatement(
        mode: InsertMode.replace,
        table: TableReference('tbl'),
        targetColumns: const [],
        source: SelectInsertSource(
          SelectStatement(
            columns: [StarResultColumn(null)],
            from: TableReference('tbl'),
          ),
        ),
      ),
    );
  });

  group('parses upsert clauses', () {
    const prefix = 'INSERT INTO tbl DEFAULT VALUES ON CONFLICT';
    test('without listing indexed columns', () {
      testStatement(
        '$prefix DO NOTHING',
        InsertStatement(
          table: TableReference('tbl'),
          targetColumns: const [],
          source: DefaultValues(),
          upsert: UpsertClause([UpsertClauseEntry(action: DoNothing())]),
        ),
      );
    });

    test('listing indexed columns without where clause', () {
      testStatement(
        '$prefix (foo, bar DESC) DO NOTHING',
        InsertStatement(
          table: TableReference('tbl'),
          targetColumns: const [],
          source: DefaultValues(),
          upsert: UpsertClause(
            [
              UpsertClauseEntry(
                onColumns: [
                  IndexedColumn(Reference(columnName: 'foo')),
                  IndexedColumn(
                    Reference(columnName: 'bar'),
                    OrderingMode.descending,
                  ),
                ],
                action: DoNothing(),
              ),
            ],
          ),
        ),
      );
    });

    test('listing indexed columns and where clause', () {
      testStatement(
        '$prefix (foo, bar) WHERE 2 = foo DO NOTHING',
        InsertStatement(
          table: TableReference('tbl'),
          targetColumns: const [],
          source: DefaultValues(),
          upsert: UpsertClause(
            [
              UpsertClauseEntry(
                onColumns: [
                  IndexedColumn(Reference(columnName: 'foo')),
                  IndexedColumn(Reference(columnName: 'bar')),
                ],
                where: BinaryExpression(
                  NumericLiteral(2, token(TokenType.numberLiteral)),
                  token(TokenType.equal),
                  Reference(columnName: 'foo'),
                ),
                action: DoNothing(),
              ),
            ],
          ),
        ),
      );
    });

    test('having an update action without where', () {
      testStatement(
        '$prefix DO UPDATE SET foo = 2',
        InsertStatement(
          table: TableReference('tbl'),
          targetColumns: const [],
          source: DefaultValues(),
          upsert: UpsertClause(
            [
              UpsertClauseEntry(
                action: DoUpdate(
                  [
                    SetComponent(
                      column: Reference(columnName: 'foo'),
                      expression:
                          NumericLiteral(2, token(TokenType.numberLiteral)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });

    test('having an update action with where', () {
      testStatement(
        '$prefix DO UPDATE SET foo = 2 WHERE ?',
        InsertStatement(
          table: TableReference('tbl'),
          targetColumns: const [],
          source: DefaultValues(),
          upsert: UpsertClause(
            [
              UpsertClauseEntry(
                action: DoUpdate(
                  [
                    SetComponent(
                      column: Reference(columnName: 'foo'),
                      expression:
                          NumericLiteral(2, token(TokenType.numberLiteral)),
                    ),
                  ],
                  where: NumberedVariable(
                    QuestionMarkVariableToken(fakeSpan('?'), null),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });

    test('having more than one clause', () {
      testStatement(
        '$prefix (foo) DO NOTHING ON CONFLICT (bar) DO UPDATE SET x = 2',
        InsertStatement(
          table: TableReference('tbl'),
          targetColumns: const [],
          source: DefaultValues(),
          upsert: UpsertClause(
            [
              UpsertClauseEntry(
                onColumns: [IndexedColumn(Reference(columnName: 'foo'))],
                action: DoNothing(),
              ),
              UpsertClauseEntry(
                onColumns: [IndexedColumn(Reference(columnName: 'bar'))],
                action: DoUpdate(
                  [
                    SetComponent(
                      column: Reference(columnName: 'x'),
                      expression:
                          NumericLiteral(2, token(TokenType.numberLiteral)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  });

  test('parses RETURNING clause', () {
    testStatement(
      'INSERT INTO tbl DEFAULT VALUES RETURNING foo, 3, bar;',
      InsertStatement(
        table: TableReference('tbl'),
        targetColumns: const [],
        source: DefaultValues(),
        returning: Returning([
          ExpressionResultColumn(expression: Reference(columnName: 'foo')),
          ExpressionResultColumn(
            expression: NumericLiteral(3, token(TokenType.numberLiteral)),
          ),
          ExpressionResultColumn(expression: Reference(columnName: 'bar')),
        ]),
      ),
    );
  });
}
