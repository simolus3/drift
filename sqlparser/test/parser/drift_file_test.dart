import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import 'utils.dart';

const content = r'''
import 'other.dart';
import 'another.drift';

CREATE TABLE tbl (
  id INT NOT NULL PRIMARY KEY AUTOINCREMENT,
  -- this is a single-line comment
  place VARCHAR REFERENCES other(location) AS "placeRef"
) AS RowName;

all: SELECT /* COUNT(*), */ * FROM tbl WHERE $predicate;
@special: SELECT * FROM tbl;
typeHints(REQUIRED :foo AS TEXT OR NULL, $predicate = TRUE):
  SELECT :foo WHERE $predicate;
nested AS MyResultSet: SELECT foo.** AS fooRename FROM tbl foo;
add: INSERT INTO tbl $row RETURNING *;
''';

void main() {
  test('parses drift files', () {
    testDriftFile(
      content,
      DriftFile([
        ImportStatement('other.dart'),
        ImportStatement('another.drift'),
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
                DriftDartName(null, identifier('placeRef')),
              ],
            ),
          ],
          driftTableName: DriftTableName('RowName', false),
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
              BooleanLiteral(true),
            ),
          ],
        ),
        DeclaredStatement(
          SimpleName('nested'),
          SelectStatement(
            columns: [
              NestedStarResultColumn(
                tableName: 'foo',
                as: 'fooRename',
              )
            ],
            from: TableReference('tbl', as: 'foo'),
          ),
          as: DriftTableName('MyResultSet', false),
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
    testDriftFile(
      '''
test: BEGIN
  UPDATE foo SET bar = baz;
  DELETE FROM t;
END;
''',
      DriftFile([
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
    // regression test for https://github.com/simolus3/drift/issues/280#issuecomment-570789454
    final parsed = SqlEngine(EngineOptions(useDriftExtensions: true))
        .parseDriftFile('name: NSERT INTO foo DEFAULT VALUES;');

    expect(
      parsed.errors,
      contains(const TypeMatcher<ParsingError>().having(
        (e) => e.message,
        'message',
        contains('Expected a sql statement here'),
      )),
    );

    final root = parsed.rootNode as DriftFile;
    expect(
      root.allDescendants,
      isNot(contains(const TypeMatcher<DeclaredStatement>())),
    );
  });

  test('syntax errors contain correct position', () {
    final engine = SqlEngine(EngineOptions(useDriftExtensions: true));
    final result = engine.parseDriftFile('''
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
    testDriftFile(
      'test(REQUIRED :category): SELECT :category;',
      DriftFile([
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

  test('allows statements to appear in any order', () {
    final result =
        SqlEngine(EngineOptions(useDriftExtensions: true)).parseDriftFile('''
CREATE TABLE foo (
  a INTEGER NOT NULL
);

import 'b.dart';

a: SELECT * FROM foo;

CREATE INDEX x ON foo (a);
''');

    expect(result.errors, isEmpty);
  });

  test('declared statements can use existing classes syntax', () {
    testDriftFile(
      'foo WITH ExistingDartClass: SELECT 1;',
      DriftFile([
        DeclaredStatement(
          SimpleName('foo'),
          as: DriftTableName('ExistingDartClass', true),
          SelectStatement(
            columns: [
              ExpressionResultColumn(expression: NumericLiteral(1)),
            ],
          ),
        ),
      ]),
    );
  });
}
