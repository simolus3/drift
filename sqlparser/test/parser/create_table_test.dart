import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/ast/ast.dart';
import 'package:test/test.dart';

import '../common_data.dart';
import 'utils.dart';

void main() {
  test('parsers simple create table statements', () {
    testStatement(
      'CREATE TABLE my_tbl (a INT, b TEXT)',
      CreateTableStatement(tableName: 'my_tbl', columns: [
        ColumnDefinition(columnName: 'a', typeName: 'INT'),
        ColumnDefinition(columnName: 'b', typeName: 'TEXT'),
      ]),
    );
  });

  test('parses complex CREATE TABLE statements', () {
    testStatement(
      createTableStmt,
      CreateTableStatement(
        tableName: 'users',
        ifNotExists: true,
        withoutRowId: false,
        columns: [
          ColumnDefinition(
            columnName: 'id',
            typeName: 'INT',
            constraints: [
              NotNull(null),
              PrimaryKeyColumn(
                null,
                autoIncrement: true,
                onConflict: ConflictClause.rollback,
                mode: OrderingMode.descending,
              ),
            ],
          ),
          ColumnDefinition(
            columnName: 'email',
            typeName: 'VARCHAR',
            constraints: [
              NotNull(null),
              UniqueColumn(null, ConflictClause.abort),
            ],
          ),
          ColumnDefinition(
            columnName: 'score',
            typeName: 'INT',
            constraints: [
              NotNull('score set'),
              Default(
                  null, NumericLiteral(420, token(TokenType.numberLiteral))),
              CheckColumn(
                null,
                BinaryExpression(
                  Reference(columnName: 'score'),
                  token(TokenType.more),
                  NumericLiteral(
                    0,
                    token(TokenType.numberLiteral),
                  ),
                ),
              ),
            ],
          ),
          ColumnDefinition(
            columnName: 'display_name',
            typeName: 'VARCHAR',
            constraints: [
              NullColumnConstraint(null),
              CollateConstraint(
                null,
                'BINARY',
              ),
              ForeignKeyColumnConstraint(
                null,
                ForeignKeyClause(
                  foreignTable: TableReference('some', null),
                  columnNames: [Reference(columnName: 'thing')],
                  onUpdate: ReferenceAction.cascade,
                  onDelete: ReferenceAction.setNull,
                  deferrable: DeferrableClause(
                    false,
                    InitialDeferrableMode.deferred,
                  ),
                ),
              ),
            ],
          )
        ],
        tableConstraints: [
          KeyClause(
            null,
            isPrimaryKey: false,
            indexedColumns: [
              Reference(columnName: 'score'),
              Reference(columnName: 'display_name'),
            ],
            onConflict: ConflictClause.abort,
          ),
          ForeignKeyTableConstraint(
            null,
            columns: [
              Reference(columnName: 'id'),
              Reference(columnName: 'email'),
            ],
            clause: ForeignKeyClause(
              foreignTable: TableReference('another', null),
              columnNames: [
                Reference(columnName: 'a'),
                Reference(columnName: 'b'),
              ],
              onDelete: ReferenceAction.noAction,
              onUpdate: ReferenceAction.restrict,
              deferrable: DeferrableClause(
                true,
                InitialDeferrableMode.immediate,
              ),
            ),
          )
        ],
      ),
    );
  });

  test('parses MAPPED BY constraints when in moor mode', () {
    testStatement(
      'CREATE TABLE a (b NOT NULL MAPPED BY `Mapper()` PRIMARY KEY)',
      CreateTableStatement(tableName: 'a', columns: [
        ColumnDefinition(
          columnName: 'b',
          typeName: null,
          constraints: [
            NotNull(null),
            MappedBy(null, inlineDart('Mapper()')),
            PrimaryKeyColumn(null),
          ],
        ),
      ]),
      moorMode: true,
    );
  });

  test('parses JSON KEY constraints in moor mode', () {
    testStatement(
      'CREATE TABLE a (b INTEGER JSON KEY "my_json_key")',
      CreateTableStatement(
        tableName: 'a',
        columns: [
          ColumnDefinition(
            columnName: 'b',
            typeName: 'INTEGER',
            constraints: [
              JsonKey(
                null,
                identifier('my_json_key'),
              ),
            ],
          ),
        ],
      ),
      moorMode: true,
    );
  });

  test('parses CREATE VIRTUAL TABLE statement', () {
    testStatement(
      'CREATE VIRTUAL TABLE IF NOT EXISTS foo USING bar(a, b(), c) AS moor',
      CreateVirtualTableStatement(
        ifNotExists: true,
        tableName: 'foo',
        moduleName: 'bar',
        arguments: [
          fakeSpan('a'),
          fakeSpan('b()'),
          fakeSpan('c'),
        ],
        overriddenDataClassName: 'moor',
      ),
      moorMode: true,
    );
  });

  test('parses CREATE VIRTUAL TABLE statement without args', () {
    testStatement(
      'CREATE VIRTUAL TABLE foo USING bar;',
      CreateVirtualTableStatement(
        tableName: 'foo',
        moduleName: 'bar',
        arguments: [],
      ),
    );
  });

  test("can't have empty arguments in CREATE VIRTUAL TABLE", () {
    final engine = SqlEngine();
    expect(
      engine.parse('CREATE VIRTUAL TABLE foo USING bar(a,)').errors,
      contains(
        const TypeMatcher<ParsingError>()
            .having((e) => e.token.lexeme, 'fails at closing bracket', ')'),
      ),
    );

    expect(
      engine.parse('CREATE VIRTUAL TABLE foo USING bar(a,,b)').errors,
      contains(
        const TypeMatcher<ParsingError>()
            .having((e) => e.token.lexeme, 'fails at next comma', ','),
      ),
    );
  });
}
