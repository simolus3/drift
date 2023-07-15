import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/utils/ast_equality.dart';
import 'package:sqlparser/utils/node_to_text.dart';
import 'package:test/test.dart';

enum _ParseKind {
  statement,
  driftFile,
  multipleStatements,
}

void main() {
  final engine =
      SqlEngine(EngineOptions(driftOptions: const DriftSqlOptions()));

  void testFormat(String input,
      {_ParseKind kind = _ParseKind.statement, String? expectedOutput}) {
    AstNode parse(String input) {
      late ParseResult result;

      switch (kind) {
        case _ParseKind.statement:
          result = engine.parse(input);
          break;
        case _ParseKind.driftFile:
          result = engine.parseDriftFile(input);
          break;
        case _ParseKind.multipleStatements:
          result = engine.parseMultiple(input);
          break;
      }

      if (result.errors.isNotEmpty) {
        fail('Error parsing $input: ${result.errors.join('\n')}');
      }

      return result.rootNode;
    }

    final originalAst = parse(input);
    final formatted = originalAst.toSql();

    if (expectedOutput != null) {
      expect(formatted, expectedOutput);
    } else {
      // Just make sure we emit something equal to what we got
      final newAst = parse(formatted);

      try {
        enforceEqual(originalAst, newAst);
      } catch (e) {
        fail('Not equal after formatting: $input to $formatted: $e');
      }
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

      test('Using RAISE', () {
        testFormat('''
CREATE TRIGGER my_trigger AFTER DELETE ON t1 BEGIN
  SELECT RAISE(ABORT, 'please don''t');
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

    group('table', () {
      test('complex', () {
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
      });

      test('WITHOUT ROWID', () {
        testFormat('''
CREATE TABLE IF NOT EXISTS my_table(
  foo INTEGER NOT NULL PRIMARY KEY ASC
) WITHOUT ROWID;
      ''');
      });

      test('STRICT', () {
        testFormat('''
CREATE TABLE IF NOT EXISTS my_table(
  foo INTEGER NOT NULL PRIMARY KEY ASC
) STRICT;
      ''');
      });

      test('STRICT and WITHOUT ROWID', () {
        testFormat('''
CREATE TABLE IF NOT EXISTS my_table(
  foo INTEGER NOT NULL PRIMARY KEY ASC
) WITHOUT ROWID, STRICT;
      ''');
      });

      test('with existing row class', () {
        testFormat('''
CREATE TABLE foo (bar INTEGER NOT NULL PRIMARY KEY) With FooData.myConstructor;
''');
      });

      test('virtual', () {
        testFormat('CREATE VIRTUAL TABLE foo USING bar(a, b, c);');
      });
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

  group('misc', () {
    test('transactions', () {
      testFormat('BEGIN DEFERRED TRANSACTION;');
      testFormat('BEGIN IMMEDIATE');
      testFormat('BEGIN EXCLUSIVE');

      testFormat('COMMIT');
      testFormat('END TRANSACTION');
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

      test('escapes CTEs', () {
        testFormat('WITH alias("first", second) AS (SELECT * FROM foo) '
            'SELECT * FROM alias');
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

      test('with LIST column', () {
        testFormat('SELECT LIST(SELECT * FROM foo) AS r');
      });

      test('with expression', () {
        testFormat('SELECT 1, 2 AS r, 3');
      });

      test('with mapped by column', () {
        testFormat('SELECT 1 MAPPED BY `MyEnumConverter()`');
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

      test('window function expressions', () {
        // https://github.com/simolus3/drift/issues/2273
        testFormat('''
          SELECT
            ROW_NUMBER() OVER (
              ORDER BY
                date
            ) AS rn,
            date(
              date,
              '-' || ROW_NUMBER() OVER (
                ORDER BY
                  date
              ) || ' day'
            ) AS grp,
            date
          FROM
            dates
      ''');
      });

      test('aggregate', () {
        testFormat('''
          SELECT
            subs_id, subs_name,
            COUNT(is_skipped) FILTER (WHERE is_skipped = true) skipped,
            COUNT(is_touched) FILTER (WHERE is_touched = true) touched,
            COUNT(is_passed) FILTER (WHERE is_passed = true) passed
          FROM stats
          GROUP BY subs_id;
        ''');
      });

      group('joins', () {
        for (final kind in ['LEFT', 'RIGHT', 'FULL']) {
          test(kind, () {
            testFormat('SELECT * FROM foo $kind JOIN bar;');
            testFormat('SELECT * FROM foo $kind OUTER JOIN bar;');
            testFormat('SELECT * FROM foo NATURAL $kind JOIN bar;');
            testFormat('SELECT * FROM foo NATURAL $kind OUTER JOIN bar;');
          });
        }

        test('complex', () {
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
      });

      test('table references', () {
        testFormat('SELECT * FROM foo');
        testFormat('SELECT * FROM main.foo');
      });

      test('limit', () {
        testFormat('SELECT * FROM foo LIMIT 3, 4');
        testFormat('SELECT * FROM foo LIMIT 4 OFFSET 3');
      });

      test('order by', () {
        testFormat('SELECT foo.* FROM foo ORDER BY foo NULLS FIRST');
      });
    });

    group('delete', () {
      test('with CTEs', () {
        testFormat(
            'WITH foo (id) AS (SELECT * FROM bar) DELETE FROM bar WHERE x;');
      });

      test('with returning', () {
        testFormat('DELETE FROM foo RETURNING *');
      });
    });

    group('insert', () {
      test('replace', () {
        testFormat('WITH foo (id) AS (SELECT * FROM bar) '
            'REPLACE INTO foo DEFAULT VALUES');
      });

      test('into select', () {
        testFormat('INSERT INTO foo SELECT * FROM bar');
      });

      test('with returning', () {
        testFormat('INSERT INTO foo DEFAULT VALUES RETURNING *');
      });

      test('with returning and insert mode', () {
        testFormat('INSERT OR IGNORE INTO foo DEFAULT VALUES RETURNING *');
      });

      test('upsert - do nothing', () {
        testFormat(
            'INSERT OR REPLACE INTO foo DEFAULT VALUES ON CONFLICT DO NOTHING');
      });

      test('upsert with conflict target', () {
        testFormat('INSERT INTO foo VALUES (1, 2, 3) ON CONFLICT (a, b, c) '
            'DO NOTHING;');
      });

      test('upsert with conflict target and where', () {
        testFormat('INSERT INTO foo VALUES (1, 2, 3) '
            'ON CONFLICT (a, b, c) WHERE foo = bar DO NOTHING;');
      });

      test('upsert - update', () {
        testFormat('INSERT INTO foo VALUES (1, 2, 3) '
            'ON CONFLICT DO UPDATE SET a = b, c = d WHERE d < a;');
      });

      test('upsert - multiple clauses', () {
        testFormat('INSERT INTO foo VALUES (1, 2, 3) '
            'ON CONFLICT DO NOTHING '
            'ON CONFLICT DO UPDATE SET a = b, c = d WHERE d < a;');
      });
    });

    group('update', () {
      test('simple', () {
        testFormat('UPDATE foo SET bar = baz WHERE 1;');
      });

      test('with returning', () {
        testFormat('UPDATE foo SET bar = baz RETURNING *');
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

    test('is DISTINCT FROM', () {
      testFormat('SELECT foo IS DISTINCT FROM bar',
          expectedOutput: 'SELECT foo IS NOT bar');

      testFormat('SELECT foo IS NOT DISTINCT FROM bar',
          expectedOutput: 'SELECT foo IS bar');
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

    test('references', () {
      testFormat('SELECT foo');
      testFormat('SELECT foo.bar');
      testFormat('SELECT foo.bar.baz');
    });

    test('json', () {
      testFormat('SELECT a -> b');
      testFormat('SELECT a ->> b');
    });
  });

  test('identifiers', () {
    void testWith(String id, String formatted) {
      final node = Reference(columnName: id);
      expect(node.toSql(), formatted);
    }

    testWith('a', 'a');
    testWith('_', '_');
    testWith('c0', 'c0');
    testWith('_c0', '_c0');
    testWith('a b', '"a b"');
    testWith(r'a$b', r'"a$b"');
  });

  group('drift', () {
    group('dart placeholders', () {
      test('expression', () {
        testFormat(r'SELECT $placeholder FROM foo');
      });

      test('limit', () {
        testFormat(r'SELECT * FROM foo LIMIT $limit');
      });

      test('ordering term', () {
        testFormat(r'SELECT * FROM foo ORDER BY $term DESC');
      });

      test('order by clause', () {
        testFormat(r'SELECT * FROM foo ORDER BY $clause');
      });

      test('insertable', () {
        testFormat(r'INSERT INTO foo $companion');
      });
    });

    test('imports', () {
      testFormat('import \'foo.bar\';', kind: _ParseKind.driftFile);
    });

    test('declared statements', () {
      testFormat('foo (?1 AS INT): SELECT * FROM bar WHERE ? < 10;',
          kind: _ParseKind.driftFile);
      testFormat('foo: SELECT * FROM bar WHERE :id < 10;',
          kind: _ParseKind.driftFile);
      testFormat('foo (REQUIRED :x AS TEXT OR NULL): SELECT :x;',
          kind: _ParseKind.driftFile);
      testFormat(r'foo ($pred = FALSE): SELECT * FROM bar WHERE $pred;',
          kind: _ParseKind.driftFile);
    });

    test('nested star', () {
      testFormat('q: SELECT foo.** FROM foo;', kind: _ParseKind.driftFile);
    });

    test('transaction block', () {
      testFormat(
        '''
test: BEGIN TRANSACTION
  SELECT * FROM foo;
  UPDATE foo SET bar = baz;
  DELETE FROM x;
  INSERT INTO foo VALUES (x, y, z);
COMMIT TRANSACTION;
''',
        kind: _ParseKind.driftFile,
      );
    });
  });

  test('does not format invalid statements', () {
    expect(InvalidStatement().toSql, throwsUnsupportedError);
  });

  test('multiple statements', () {
    testFormat('''
CREATE TABLE my_table (
  id INTEGER NOT NULL PRIMARY KEY,
  another TEXT
) STRICT;

BEGIN;

INSERT INTO foo (bar, baz) VALUES ('hi', 3);

COMMIT;
''', kind: _ParseKind.multipleStatements);
  });
}
