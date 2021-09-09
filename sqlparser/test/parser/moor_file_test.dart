import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import 'utils.dart';

const content = r'''
import 'other.dart';
import 'another.moor';

CREATE TABLE tbl (
  id INT NOT NULL PRIMARY KEY AUTOINCREMENT,
  -- this is a single-line comment
  place VARCHAR REFERENCES other(location) AS "placeRef"
) AS RowName;

all: SELECT /* COUNT(*), */ * FROM tbl WHERE $predicate;
@special: SELECT * FROM tbl;
typeHints(REQUIRED :foo AS TEXT OR NULL, $predicate = TRUE):
  SELECT :foo WHERE $predicate;
nested AS MyResultSet: SELECT foo.** FROM tbl foo;
add: INSERT INTO tbl $row RETURNING *;
''';

void main() {
  test('parses moor files', () {
    testMoorFile(
      content,
      MoorFile([
        ImportStatement('other.dart'),
        ImportStatement('another.moor'),
        CreateTableStatement(
          tableName: 'tbl',
          columns: [
            ColumnDefinition(
              columnName: 'id',
              typeName: 'INT',
              constraints: [
                NotNull(null),
                PrimaryKeyColumn(null, autoIncrement: true),
              ],
            ),
            ColumnDefinition(
              columnName: 'place',
              typeName: 'VARCHAR',
              constraints: [
                ForeignKeyColumnConstraint(
                  null,
                  ForeignKeyClause(
                    foreignTable: TableReference('other'),
                    columnNames: [
                      Reference(columnName: 'location'),
                    ],
                  ),
                ),
                MoorDartName(null, identifier('placeRef')),
              ],
            ),
          ],
          moorTableName: MoorTableName('RowName', false),
        ),
        DeclaredStatement(
          SimpleName('all'),
          SelectStatement(
            columns: [StarResultColumn(null)],
            from: TableReference('tbl'),
            where: DartExpressionPlaceholder(name: 'predicate'),
          ),
        ),
        DeclaredStatement(
          SpecialStatementIdentifier('special'),
          SelectStatement(
            columns: [StarResultColumn(null)],
            from: TableReference('tbl'),
          ),
        ),
        DeclaredStatement(
          SimpleName('typeHints'),
          SelectStatement(
            columns: [
              ExpressionResultColumn(
                expression: ColonNamedVariable(
                  ColonVariableToken(fakeSpan(':foo'), ':foo'),
                ),
              ),
            ],
            where: DartExpressionPlaceholder(name: 'predicate'),
          ),
          parameters: [
            VariableTypeHint(
              ColonNamedVariable(
                ColonVariableToken(fakeSpan(':foo'), ':foo'),
              ),
              'TEXT',
              orNull: true,
              isRequired: true,
            ),
            DartPlaceholderDefaultValue(
              'predicate',
              BooleanLiteral.withTrue(token(TokenType.$true)),
            ),
          ],
        ),
        DeclaredStatement(
          SimpleName('nested'),
          SelectStatement(
            columns: [NestedStarResultColumn('foo')],
            from: TableReference('tbl', as: 'foo'),
          ),
          as: 'MyResultSet',
        ),
        DeclaredStatement(
          SimpleName('add'),
          InsertStatement(
            table: TableReference('tbl'),
            source: DartInsertablePlaceholder(name: 'row'),
            targetColumns: const [],
            returning: Returning([
              StarResultColumn(),
            ]),
          ),
        )
      ]),
    );
  });

  test('parses transaction blocks', () {
    testMoorFile(
      '''
test: BEGIN
  UPDATE foo SET bar = baz;
  DELETE FROM t;
END;
''',
      MoorFile([
        DeclaredStatement(
          SimpleName('test'),
          TransactionBlock(
            begin: BeginTransactionStatement(),
            innerStatements: [
              UpdateStatement(
                table: TableReference('foo'),
                set: [
                  SetComponent(
                    column: Reference(columnName: 'bar'),
                    expression: Reference(columnName: 'baz'),
                  ),
                ],
              ),
              DeleteStatement(from: TableReference('t')),
            ],
            commit: CommitStatement(),
          ),
        ),
      ]),
    );
  });

  test("reports error when the statement can't be parsed", () {
    // regression test for https://github.com/simolus3/moor/issues/280#issuecomment-570789454
    final parsed = SqlEngine(EngineOptions(useMoorExtensions: true))
        .parseMoorFile('name: NSERT INTO foo DEFAULT VALUES;');

    expect(
      parsed.errors,
      contains(const TypeMatcher<ParsingError>().having(
        (e) => e.message,
        'message',
        contains('Expected a sql statement here'),
      )),
    );

    final root = parsed.rootNode as MoorFile;
    expect(
      root.allDescendants,
      isNot(contains(const TypeMatcher<DeclaredStatement>())),
    );
  });

  test('syntax errors contain correct position', () {
    final engine = SqlEngine(EngineOptions(useMoorExtensions: true));
    final result = engine.parseMoorFile('''
worksByComposer:
SELECT DISTINCT A.* FROM works A, works B ON A.id = 
    WHERE A.composer = :id OR B.composer = :id;
    ''');

    expect(result.errors, hasLength(1));
    expect(
        result.errors.single,
        isA<ParsingError>()
            .having((e) => e.token.lexeme, 'token.lexeme', 'WHERE'));
  });

  test('parses REQUIRED without type hint', () {
    final variable = ColonVariableToken(fakeSpan(':category'), ':category');
    testMoorFile(
      'test(REQUIRED :category): SELECT :category;',
      MoorFile([
        DeclaredStatement(
          SimpleName('test'),
          SelectStatement(columns: [
            ExpressionResultColumn(
              expression: ColonNamedVariable(variable),
            ),
          ]),
          parameters: [
            VariableTypeHint(
              ColonNamedVariable(variable),
              null,
              isRequired: true,
            ),
          ],
        ),
      ]),
    );
  });
}
