import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/utils/ast_equality.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test('can parse multiple statements', () {
    const sql = 'a: UPDATE tbl SET a = b; b: SELECT * FROM tbl;';

    testDriftFile(
      sql,
      DriftFile([
        DeclaredStatement(
          SimpleName('a'),
          UpdateStatement(
            table: TableReference('tbl'),
            set: [
              SingleColumnSetComponent(
                column: Reference(columnName: 'a'),
                expression: Reference(columnName: 'b'),
              ),
            ],
          ),
        ),
        DeclaredStatement(
          SimpleName('b'),
          SelectStatement(
            columns: [StarResultColumn(null)],
            from: TableReference('tbl'),
          ),
        ),
      ]),
    );
  });

  test('recovers from invalid statements', () {
    const sql = 'a: UPDATE tbl SET a = * d; b: SELECT * FROM tbl;';
    final statements = SqlEngine()
        .parse(ParserEntrypoint.driftFile, sql)
        .rootNode
        .statements;

    expect(statements, hasLength(1));
    enforceEqual(
      statements[0],
      DeclaredStatement(
        SimpleName('b'),
        SelectStatement(
          columns: [StarResultColumn(null)],
          from: TableReference('tbl'),
        ),
      ),
    );
  });

  test('parses imports and declared statements in drift mode', () {
    const sql = r'''
    import 'test.dart';
    query: SELECT * FROM tbl;
     ''';

    final parseResult = SqlEngine(
      EngineOptions(driftOptions: DriftSqlOptions()),
    ).parse(ParserEntrypoint.driftFile, sql);
    final statements = parseResult.rootNode.statements;
    final tokens = parseResult.tokens;

    expect(statements, hasLength(2));

    final parsedImport = statements[0] as ImportStatement;
    enforceEqual(parsedImport, ImportStatement('test.dart'));
    expect(parsedImport.importToken, tokens[0]);
    expect(parsedImport.importString, tokens[1]);
    expect(parsedImport.semicolon, tokens[2]);

    final declared = statements[1] as DeclaredStatement;
    enforceEqual(
      declared,
      DeclaredStatement(
        SimpleName('query'),
        SelectStatement(
          columns: [StarResultColumn(null)],
          from: TableReference('tbl'),
        ),
      ),
    );
  });

  test('parses multiple statements with parseMultiple()', () {
    const sql = '''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY,
      name TEXT,
      email TEXT
    );

    SELECT * FROM users WHERE id = 1;

    INSERT INTO users (name, email) VALUES ('John Doe', 'john@example.com');
  ''';

    final engine = SqlEngine();
    final ast = engine.parse(ParserEntrypoint.multiple, sql).rootNode;
    enforceHasSpan(ast);

    enforceEqual(
      ast,
      SemicolonSeparatedStatements([
        CreateTableStatement(
          tableName: 'users',
          columns: [
            ColumnDefinition(
              columnName: 'id',
              typeName: 'INTEGER',
              constraints: [PrimaryKeyColumn(null)],
            ),
            ColumnDefinition(columnName: 'name', typeName: 'TEXT'),
            ColumnDefinition(columnName: 'email', typeName: 'TEXT'),
          ],
        ),
        SelectStatement(
          columns: [StarResultColumn()],
          from: TableReference('users'),
          where: BinaryExpression(
            Reference(columnName: 'id'),
            token(TokenType.equal),
            NumericLiteral(1),
          ),
        ),
        InsertStatement(
          table: TableReference('users'),
          targetColumns: [
            Reference(columnName: 'name'),
            Reference(columnName: 'email'),
          ],
          source: ValuesSource([
            Tuple(
              expressions: [
                StringLiteral('John Doe'),
                StringLiteral('john@example.com'),
              ],
            ),
          ]),
        ),
      ]),
    );
  });

  test('parseMultiple reports spans for invalid statements', () {
    const sql = '''
UPDATE users SET foo = bar;
ALTER TABLE this syntax is not yet supported;
SELECT * FROM users;
''';

    final engine = SqlEngine();
    final ast = engine.parse(ParserEntrypoint.multiple, sql).rootNode;
    enforceHasSpan(ast);

    final statements = ast.childNodes.toList();
    expect(statements, hasLength(3));

    expect(
      statements[0],
      isA<UpdateStatement>().having(
        (e) => e.span?.text,
        'span',
        'UPDATE users SET foo = bar;',
      ),
    );
    expect(
      statements[1],
      isA<InvalidStatement>().having(
        (e) => e.span?.text,
        'span',
        'ALTER TABLE this syntax is not yet supported;',
      ),
    );
    expect(
      statements[2],
      isA<SelectStatement>().having(
        (e) => e.span?.text,
        'span',
        'SELECT * FROM users;',
      ),
    );
  });

  test('empty statement', () {
    final engine = SqlEngine();
    final result = engine.parse(
      ParserEntrypoint.multiple,
      'SELECT 1; ; SELECT 2;',
    );
    final ast = result.rootNode;

    final statements = ast.childNodes.toList();
    expect(statements, [
      isA<SelectStatement>(),
      isA<InvalidStatement>(),
      isA<SelectStatement>(),
    ]);
    expect(result.errors, isEmpty);
  });

  test('syntax error at start of statement', () {
    final engine = SqlEngine();
    final result = engine.parse(
      ParserEntrypoint.multiple,
      'SELECT 1; ILLEGAL SYNTAX; SELECT 2;',
    );
    final ast = result.rootNode;

    final statements = ast.childNodes.toList();
    expect(statements, [
      isA<SelectStatement>(),
      isA<InvalidStatement>(),
      isA<SelectStatement>(),
    ]);
    expect(result.errors, [isParsingError(span: 'ILLEGAL')]);
  });
}
