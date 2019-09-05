import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/reader/parser/parser.dart';
import 'package:sqlparser/src/reader/tokenizer/scanner.dart';
import 'package:sqlparser/src/utils/ast_equality.dart';
import 'package:test/test.dart';

void main() {
  test('can parse multiple statements', () {
    final sql = 'UPDATE tbl SET a = b; SELECT * FROM tbl;';
    final tokens = Scanner(sql).scanTokens();
    final statements = Parser(tokens).statements();

    enforceEqual(
      statements[0],
      UpdateStatement(
        table: TableReference('tbl', null),
        set: [
          SetComponent(
            column: Reference(columnName: 'a'),
            expression: Reference(columnName: 'b'),
          ),
        ],
      ),
    );
    enforceEqual(
      statements[1],
      SelectStatement(
        columns: [StarResultColumn(null)],
        from: [TableReference('tbl', null)],
      ),
    );
  });

  test('recovers from invalid statements', () {
    final sql = 'UPDATE tbl SET a = * d; SELECT * FROM tbl;';
    final tokens = Scanner(sql).scanTokens();
    final statements = Parser(tokens).statements();

    expect(statements, hasLength(1));
    enforceEqual(
      statements[0],
      SelectStatement(
        columns: [StarResultColumn(null)],
        from: [TableReference('tbl', null)],
      ),
    );
  });

  test('parses import directives in moor mode', () {
    final sql = r'''
    import 'test.dart';
    SELECT * FROM tbl;
     ''';

    final tokens = Scanner(sql, scanMoorTokens: true).scanTokens();
    final statements = Parser(tokens, useMoor: true).statements();

    expect(statements, hasLength(2));

    final parsedImport = statements[0] as ImportStatement;
    enforceEqual(parsedImport, ImportStatement('test.dart'));
    expect(parsedImport.importToken, tokens[0]);
    expect(parsedImport.importString, tokens[1]);
    expect(parsedImport.semicolon, tokens[2]);
  });
}
