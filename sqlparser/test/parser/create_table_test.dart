import 'package:sqlparser/sqlparser.dart';
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
              Default(null, NumericLiteral(420)),
              CheckColumn(
                null,
                BinaryExpression(
                  Reference(columnName: 'score'),
                  token(TokenType.more),
                  NumericLiteral(0),
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
                  foreignTable: TableReference('some'),
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
            columns: [
              IndexedColumn(Reference(columnName: 'score')),
              IndexedColumn(Reference(columnName: 'display_name')),
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
              foreignTable: TableReference('another'),
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

  test('parses KEY ORDERING in PRIMARY KEY clause', () {
    testStatement(
      'CREATE TABLE a (b TEXT, PRIMARY KEY (b DESC))',
      CreateTableStatement(
        tableName: 'a',
        columns: [ColumnDefinition(columnName: 'b', typeName: 'TEXT')],
        tableConstraints: [
          KeyClause(
            null,
            isPrimaryKey: true,
            columns: [
              IndexedColumn(
                Reference(columnName: 'b'),
                OrderingMode.descending,
              ),
            ],
          ),
        ],
      ),
    );
  });

  test('parses GENERATED AS', () {
    final expr = FunctionExpression(
      name: 'UPPER',
      parameters: ExprFunctionParameters(
        parameters: [Reference(columnName: 'a')],
      ),
    );

    testStatement(
      '''
        CREATE TABLE a (
          a TEXT,
          b TEXT GENERATED ALWAYS AS (UPPER(a)) STORED,
          c TEXT GENERATED ALWAYS AS (UPPER(a)) VIRTUAL,
          d TEXT GENERATED ALWAYS AS (UPPER(a))
        )
      ''',
      CreateTableStatement(
        tableName: 'a',
        columns: [
          ColumnDefinition(columnName: 'a', typeName: 'TEXT'),
          ColumnDefinition(columnName: 'b', typeName: 'TEXT', constraints: [
            GeneratedAs(expr, stored: true),
          ]),
          ColumnDefinition(columnName: 'c', typeName: 'TEXT', constraints: [
            GeneratedAs(expr, stored: false),
          ]),
          ColumnDefinition(columnName: 'd', typeName: 'TEXT', constraints: [
            GeneratedAs(expr, stored: false),
          ])
        ],
      ),
    );
  });

  test('parses MAPPED BY constraints when in drift mode', () {
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
      driftMode: true,
    );
  });

  test('parses JSON KEY constraints in drift mode', () {
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
      driftMode: true,
    );
  });

  test('parses CREATE TABLE WITH in drift mode', () {
    testStatement(
      'CREATE TABLE a (b INTEGER) WITH MyExistingClass',
      CreateTableStatement(
        tableName: 'a',
        columns: [
          ColumnDefinition(
            columnName: 'b',
            typeName: 'INTEGER',
          ),
        ],
        driftTableName: DriftTableName(
          overriddenDataClassName: 'MyExistingClass',
          useExistingDartClass: true,
        ),
      ),
      driftMode: true,
    );
  });

  test('parses custom types in drift mode', () {
    testStatement(
      'CREATE TABLE a (b `PgTypes.uuid` NOT NULL)',
      CreateTableStatement(
        tableName: 'a',
        columns: [
          ColumnDefinition(
            columnName: 'b',
            typeName: '`PgTypes.uuid`',
            constraints: [NotNull(null)],
          ),
        ],
      ),
      driftMode: true,
    );
  });

  test('parses CREATE VIRTUAL TABLE statement', () {
    testStatement(
      'CREATE VIRTUAL TABLE IF NOT EXISTS foo USING bar(a, b(), c) AS drift',
      CreateVirtualTableStatement(
        ifNotExists: true,
        tableName: 'foo',
        moduleName: 'bar',
        arguments: [
          fakeSpan('a'),
          fakeSpan('b()'),
          fakeSpan('c'),
        ],
        driftTableName: DriftTableName(
          overriddenDataClassName: 'drift',
          useExistingDartClass: false,
        ),
      ),
      driftMode: true,
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

  test('parses WITHOUT ROWID and STRICT', () {
    testStatement(
      'CREATE TABLE a (c INTEGER) STRICT, WITHOUT ROWID, STRICT',
      CreateTableStatement(
        tableName: 'a',
        columns: [
          ColumnDefinition(columnName: 'c', typeName: 'INTEGER'),
        ],
        withoutRowId: true,
        isStrict: true,
      ),
    );
  });

  test('parses DEFAULT with a negative literal', () {
    // regression test for https://github.com/simolus3/drift/discussions/1550
    testStatement(
      'CREATE TABLE a (b INTEGER NOT NULL DEFAULT -1);',
      CreateTableStatement(
        tableName: 'a',
        columns: [
          ColumnDefinition(columnName: 'b', typeName: 'INTEGER', constraints: [
            NotNull(null),
            Default(
              null,
              UnaryExpression(
                Token(TokenType.minus, fakeSpan('-')),
                NumericLiteral(1),
              ),
            )
          ])
        ],
      ),
    );
  });
}
