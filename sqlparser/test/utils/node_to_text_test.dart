import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/utils/ast_equality.dart';
import 'package:sqlparser/utils/node_to_text.dart';
import 'package:test/test.dart';

enum _ParseKind { statement, moorFile }

void main() {
  final engine = SqlEngine(EngineOptions(useMoorExtensions: true));

  void testFormat(String input, {_ParseKind kind = _ParseKind.statement}) {
    AstNode parse(String input) {
      ParseResult result;

      switch (kind) {
        case _ParseKind.statement:
          result = engine.parse(input);
          break;
        case _ParseKind.moorFile:
          result = engine.parseMoorFile(input);
          break;
      }

      if (result.errors.isNotEmpty) {
        fail('Error parsing $input: ${result.errors.join('\n')}');
      }

      return result.rootNode;
    }

    final originalAst = parse(input);
    final formatted = originalAst.toSql();
    final newAst = parse(formatted);

    try {
      enforceEqual(originalAst, newAst);
    } catch (e) {
      fail('Not equal after formatting: $input to $formatted: $e');
    }
  }

  test('integration test', () {
    testFormat('''
import 'foo.bar';
    ''', kind: _ParseKind.moorFile);
  });

  group('create', () {
    group('trigger', () {
      test('before delete', () {
        testFormat('''
CREATE TRIGGER IF NOT EXISTS my_trigger BEFORE DELETE ON t1 BEGIN
  SELECT * FROM t2;
END;
      ''');
      });

      test('instead of insert', () {
        testFormat('''
CREATE TRIGGER IF NOT EXISTS my_trigger INSTEAD OF INSERT ON t1 BEGIN
  SELECT * FROM t2;
END;
      ''');
      });

      test('after update', () {
        testFormat('''
CREATE TRIGGER IF NOT EXISTS my_trigger AFTER UPDATE ON t1 BEGIN
  SELECT * FROM t2;
END;
      ''');
      });

      test('after update of when', () {
        testFormat('''
CREATE TRIGGER IF NOT EXISTS my_trigger AFTER UPDATE OF c1, c2 ON t1 
  WHEN foo = bar
BEGIN
  SELECT * FROM t2;
END;
      ''');
      });
    });

    test('view', () {
      testFormat('''
CREATE VIEW my_view (foo, bar) AS SELECT * FROM t1;
      ''');

      testFormat('''
CREATE VIEW my_view AS SELECT * FROM t1;
      ''');
    });

    test('table', () {
      testFormat('''
CREATE TABLE IF NOT EXISTS my_table(
  foo TEXT NOT NULL PRIMARY KEY,
  baz INT CONSTRAINT not_null NOT NULL PRIMARY KEY AUTOINCREMENT,
  bar TEXT
    UNIQUE ON CONFLICT IGNORE
    CHECK (3 * 4 = 12)
    DEFAULT 'some string here'
    COLLATE c
    REFERENCES t2 (c) ON DELETE RESTRICT ON UPDATE NO ACTION,

  PRIMARY KEY (foo, bar) ON CONFLICT ABORT,
  UNIQUE (baz) ON CONFLICT REPLACE,
  CONSTRAINT my_constraint CHECK(baz < 3),
  FOREIGN KEY (foo, baz) REFERENCES t2 ON DELETE SET NULL ON UPDATE CASCADE
    DEFERRABLE INITIALLY IMMEDIATE
);
      ''');

      testFormat('''
CREATE TABLE IF NOT EXISTS my_table(
  foo INTEGER NOT NULL PRIMARY KEY ASC
) WITHOUT ROWID;
      ''');
    });

    test('index', () {
      testFormat('''
CREATE INDEX my_idx ON t1 (c1, c2, c3);
      ''');

      testFormat('''
CREATE INDEX my_idx ON t1 (c1, c2, c3) WHERE c1 < c3;
      ''');
    });
  });
}
