import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/utils/ast_equality.dart';
import 'package:sqlparser/utils/node_to_text.dart';
import 'package:test/test.dart';

enum _ParseKind { statement, moorFile }

void main() {
  final engine = SqlEngine(EngineOptions(useMoorExtensions: true));

  void testFormat(String input, {_ParseKind kind = _ParseKind.statement}) {
    AstNode parse(String input) {
      late ParseResult result;

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
  foo TEXT NOT NULL PRIMARY KEY DEFAULT (3 * 4),
  baz INT CONSTRAINT not_null NOT NULL PRIMARY KEY AUTOINCREMENT,
  bar TEXT
    UNIQUE ON CONFLICT IGNORE
    CHECK (3 * 4 = 12)
    DEFAULT 'some string here'
    COLLATE c
    REFERENCES t2 (c) ON DELETE RESTRICT ON UPDATE NO ACTION,

  PRIMARY KEY (foo, bar DESC) ON CONFLICT ABORT,
  UNIQUE (baz) ON CONFLICT REPLACE,
  CONSTRAINT my_constraint CHECK(baz < 3),
  FOREIGN KEY (foo, baz) REFERENCES t2 ON DELETE SET NULL ON UPDATE CASCADE
    DEFERRABLE INITIALLY IMMEDIATE,
  FOREIGN KEY (bar) REFERENCES t2 (bax) ON DELETE SET DEFAULT NOT DEFERRABLE
);
      ''');

      testFormat('''
CREATE TABLE IF NOT EXISTS my_table(
  foo INTEGER NOT NULL PRIMARY KEY ASC
) WITHOUT ROWID;
      ''');
    });

    test('virtual table', () {
      testFormat('CREATE VIRTUAL TABLE foo USING bar(a, b, c);');
    });

    test('index', () {
      testFormat('''
CREATE INDEX my_idx ON t1 (c1, c2, c3);
      ''');

      testFormat('''
CREATE UNIQUE INDEX my_idx ON t1 (c1, c2, c3) WHERE c1 < c3;
      ''');
    });
  });

  group('escapes identifiers', () {
    test("when they're keywords", () {
      testFormat('SELECT * FROM "create";');
    });

    test('when they contain whitespace', () {
      testFormat('SELECT * FROM "my fancy table"');
    });
  });

  group('query statements', () {
    group('select', () {
      test('with common table expressions', () {
        testFormat('''
          WITH RECURSIVE foo (id) AS (VALUES(1) UNION ALL SELECT id + 1 FROM foo)
            SELECT * FROM foo;
        ''');
      });

      test('with materialized CTEs', () {
        testFormat('''
          WITH 
            foo (id) AS NOT MATERIALIZED (SELECT 1),
            bar (id) AS MATERIALIZED (SELECT 2)
          SELECT * FROM foo UNION ALL SELECT * FROM bar;
        ''');
      });

      test('compound', () {
        testFormat('''
        SELECT * FROM foo
          UNION ALL SELECT * FROM bar
          UNION SELECT * FROM baz
          INTERSECT SELECT * FROM bar2
          EXCEPT SELECT * FROM bar3
          LIMIT 5;
        ''');
      });

      test('values', () {
        testFormat('VALUES (1,2,3), (4,5,6);');
      });

      test('group by', () {
        testFormat('''
          SELECT * FROM foo
            GROUP BY a, b, c HAVING COUNT(id) > 10
        ''');
      });

      test('with windows', () {
        testFormat('''
          SELECT * FROM foo
            WINDOW my_window AS (
              PARTITION BY bar GROUPS
              BETWEEN 3 PRECEDING AND CURRENT ROW
              EXCLUDE NO OTHERS
            ),
            other AS (my_window
              ORDER BY foo DESC, bar ASC NULLS FIRST
              RANGE UNBOUNDED PRECEDING EXCLUDE CURRENT ROW
            ),
            yet_another AS (other RANGE CURRENT ROW EXCLUDE GROUP),
            finally AS (other
              RANGE BETWEEN CURRENT ROW AND 4 FOLLOWING
              EXCLUDE TIES
            )
        ''');
      });

      test('joins', () {
        testFormat('''
          SELECT * FROM
            foo AS f,
            bar
            NATURAL INNER JOIN j1 USING (foo)
            LEFT JOIN j2 ON j2.id = bar.c
            LEFT OUTER JOIN j3 ON j3.id = bar.c
            CROSS JOIN j4 ON j4.a = j3.b
            INNER JOIN (SELECT * FROM bar) AS b
            INNER JOIN table_valued_function(foo)
        ''');
      });

      test('limit', () {
        testFormat('SELECT * FROM foo LIMIT 3, 4');
        testFormat('SELECT * FROM foo LIMIT 4 OFFSET 3');
      });

      test('order by', () {
        testFormat('SELECT foo.* FROM foo ORDER BY foo NULLS FIRST');
      });
    });

    test('delete', () {
      testFormat(
          'WITH foo (id) AS (SELECT * FROM bar) DELETE FROM bar WHERE x;');
    });

    group('insert', () {
      test('replace', () {
        testFormat('WITH foo (id) AS (SELECT * FROM bar) '
            'REPLACE INTO foo DEFAULT VALUES');
      });

      test('insert into select', () {
        testFormat('INSERT INTO foo SELECT * FROM bar');
      });

      test('upsert - do nothing', () {
        testFormat(
            'INSERT OR REPLACE INTO foo DEFAULT VALUES ON CONFLICT DO NOTHING');
      });

      test('upsert - update', () {
        testFormat('INSERT INTO foo VALUES (1, 2, 3) '
            'ON CONFLICT DO UPDATE SET a = b, c = d WHERE d < a;');
      });
    });

    group('update', () {
      test('simple', () {
        testFormat('UPDATE foo SET bar = baz WHERE 1;');
      });

      const modes = [
        'OR ABORT',
        'OR FAIL',
        'OR IGNORE',
        'OR REPLACE',
        ' OR ROLLBACK',
      ];
      for (var i = 0; i < modes.length; i++) {
        test('failure mode #$i', () {
          testFormat('UPDATE ${modes[i]} foo SET bar = baz');
        });
      }

      test('from', () {
        testFormat('UPDATE foo SET bar = baz FROM t1 CROSS JOIN t2');
      });
    });
  });

  group('expressions', () {
    test('between', () {
      testFormat('SELECT x BETWEEN a AND b');
      testFormat('SELECT x NOT BETWEEN a AND b');
    });

    test('binary', () {
      testFormat('SELECT x OR y');
      testFormat('SELECT x AND y');
    });

    test('in', () {
      testFormat('SELECT x IN (SELECT * FROM foo);');
      testFormat('SELECT x NOT IN (SELECT * FROM foo);');
    });

    test('boolean literals', () {
      testFormat('SELECT TRUE OR FALSE');
    });

    test('case', () {
      testFormat('SELECT CASE WHEN a THEN b ELSE C END');
      testFormat('SELECT CASE x WHEN a THEN b WHEN c THEN d END');
    });

    test('cast', () {
      testFormat('SELECT CAST(X AS INTEGER)');
    });

    test('collate', () {
      testFormat('SELECT x COLLATE y AS xc');
    });

    test('exists', () {
      testFormat('SELECT x FROM foo WHERE EXISTS (SELECT * FROM bar)');
    });

    test('function', () {
      testFormat('SELECT my_function(*) FROM foo');
      testFormat('SELECT my_function(DISTINCT a, b) FROM foo');
      testFormat('SELECT my_function(a, b) FROM foo');
    });

    test('is', () {
      testFormat('SELECT foo IS bar');
      testFormat('SELECT foo IS NOT bar');
    });

    test('is null', () {
      testFormat('SELECT foo ISNULL');
      testFormat('SELECT foo NOTNULL');
    });

    test('null literal', () {
      testFormat('SELECT NULL;');
    });

    test('parentheses', () {
      testFormat('SELECT (3 + 4) * 5');
    });

    test('reference with table', () {
      testFormat('SELECT foo.bar FROM foo');
    });

    test('string comparison', () {
      testFormat('SELECT x LIKE y FROM foo');
    });

    test('time literals', () {
      testFormat('SELECT CURRENT_TIME;');
      testFormat('SELECT CURRENT_DATE;');
      testFormat('SELECT CURRENT_TIMESTAMP;');
    });

    test('unary expression', () {
      testFormat('SELECT -(+(~3));');
    });
  });

  group('moor', () {
    test('dart placeholders', () {
      testFormat(r'SELECT $placeholder FROM foo');
    });

    test('imports', () {
      testFormat('import \'foo.bar\';', kind: _ParseKind.moorFile);
    });

    test('declared statements', () {
      testFormat('foo (?1 AS INT): SELECT * FROM bar WHERE ? < 10;',
          kind: _ParseKind.moorFile);
      testFormat('foo: SELECT * FROM bar WHERE :id < 10;',
          kind: _ParseKind.moorFile);
      testFormat(r'foo ($pred = FALSE): SELECT * FROM bar WHERE $pred;',
          kind: _ParseKind.moorFile);
    });

    test('nested star', () {
      testFormat('q: SELECT foo.** FROM foo;', kind: _ParseKind.moorFile);
    });
  });

  test('does not format invalid statements', () {
    expect(InvalidStatement().toSql, throwsUnsupportedError);
  });
}
