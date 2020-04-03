import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import 'utils.dart';

const content = r'''
import 'other.dart';
import 'another.moor';

CREATE TABLE tbl (
  id INT NOT NULL PRIMARY KEY AUTOINCREMENT,
  -- this is a single-line comment
  place VARCHAR REFERENCES other(location)
) AS RowName;

all: SELECT /* COUNT(*), */ * FROM tbl WHERE $predicate;
@special: SELECT * FROM tbl;
typeHints(:foo AS TEXT): SELECT :foo;
nested: SELECT foo.** FROM tbl foo;
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
                    foreignTable: TableReference('other', null),
                    columnNames: [
                      Reference(columnName: 'location'),
                    ],
                  ),
                ),
              ],
            ),
          ],
          overriddenDataClassName: 'RowName',
        ),
        DeclaredStatement(
          SimpleName('all'),
          SelectStatement(
            columns: [StarResultColumn(null)],
            from: TableReference('tbl', null),
            where: DartExpressionPlaceholder(name: 'predicate'),
          ),
        ),
        DeclaredStatement(
          SpecialStatementIdentifier('special'),
          SelectStatement(
            columns: [StarResultColumn(null)],
            from: TableReference('tbl', null),
          ),
        ),
        DeclaredStatement(
          SimpleName('typeHints'),
          SelectStatement(columns: [
            ExpressionResultColumn(
              expression: ColonNamedVariable(
                ColonVariableToken(fakeSpan(':foo'), ':foo'),
              ),
            ),
          ]),
          parameters: [
            VariableTypeHint(
              ColonNamedVariable(
                ColonVariableToken(fakeSpan(':foo'), ':foo'),
              ),
              'TEXT',
            )
          ],
        ),
        DeclaredStatement(
          SimpleName('nested'),
          SelectStatement(
            columns: [NestedStarResultColumn('foo')],
            from: TableReference('tbl', 'foo'),
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
}
