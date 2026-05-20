import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/utils/schema_buffer.dart';
import 'package:test/test.dart';

import '../analysis/errors/utils.dart';

void main() {
  final engine = SqlEngine(EngineOptions(version: SqliteVersion.current));
  late SchemaBuffer buffer;
  setUp(() {
    buffer = SchemaBuffer();
  });

  void process(String text) {
    final results = engine.parse(ParserEntrypoint.multiple, text);
    expect(results.errors, isEmpty);

    for (final stmt in results.rootNode.childNodes) {
      expect(buffer.process(stmt as Statement), isEmpty);
    }
  }

  List<AnalysisError> processWithErrors(String text) {
    final results = engine.parse(ParserEntrypoint.statement, text);
    expect(results.errors, isEmpty);

    return buffer.process(results.rootNode);
  }

  group('create', () {
    test('simple', () {
      const createTable = 'CREATE TABLE foo (bar TEXT) STRICT;';
      const createIndex = 'CREATE INDEX foo_idx ON foo(bar);';
      const createView = 'CREATE VIEW foo_2 AS SELECT * FROM foo;';
      const createTrigger =
          'CREATE TRIGGER foo_trigger AFTER INSERT ON foo BEGIN DELETE FROM foo; END;';

      process('$createTable$createIndex$createView$createTrigger');

      expect(buffer.definitions, {
        'foo': createTable,
        'foo_idx': createIndex,
        'foo_2': createView,
        'foo_trigger': createTrigger,
      });
    });

    test('already exists', () {
      process('CREATE TABLE foo (bar TEXT);');
      expect(processWithErrors('CREATE TABLE foo (bar INTEGER);'), [
        analysisErrorWith(
          lexeme: 'CREATE TABLE foo (bar INTEGER);',
          message: 'Already exists',
        ),
      ]);
    });

    test('wrong type', () {
      process('CREATE TABLE foo (bar TEXT);');
      expect(processWithErrors('CREATE VIEW IF NOT EXISTS foo AS SELECT 1;'), [
        analysisErrorWith(
          lexeme: 'CREATE VIEW IF NOT EXISTS foo AS SELECT 1;',
          message:
              'A schema element of a different type with that name already exists',
        ),
      ]);
    });
  });

  group('drop', () {
    test('removes definition', () {
      process('CREATE TABLE foo (bar TEXT) STRICT; DROP TABLE "foo";');
      expect(buffer.definitions, isEmpty);
    });

    test('does not exist', () {
      expect(processWithErrors('DROP TABLE foo;'), [
        analysisErrorWith(
          lexeme: 'DROP TABLE foo;',
          message: 'Entity to drop does not exist.',
        ),
      ]);
    });

    test('wrong type', () {
      process('CREATE TABLE foo (bar TEXT);');
      expect(processWithErrors('DROP INDEX foo;'), [
        analysisErrorWith(lexeme: 'INDEX', message: 'Wrong type, is table'),
      ]);
    });
  });

  group('alter table', () {
    test('missing table', () {
      expect(processWithErrors('ALTER TABLE foo RENAME TO bar'), [
        analysisErrorWith(
          lexeme: 'foo',
          type: AnalysisErrorType.referencedUnknownTable,
        ),
      ]);
    });

    test('rename', () {
      process('CREATE TABLE original (a INTEGER) /* comment */ STRICT;');
      process('ALTER TABLE original RENAME TO changed;');

      expect(buffer.definitions, {
        'changed': 'CREATE TABLE changed (a INTEGER) /* comment */ STRICT;',
      });
    });

    test('rename to existing', () {
      process('CREATE TABLE original (a INTEGER) /* comment */ STRICT;');
      process('CREATE TABLE CHANGED (a INTEGER) /* comment */ STRICT;');

      expect(processWithErrors('ALTER TABLE original RENAME TO changed;'), [
        analysisErrorWith(lexeme: 'changed'),
      ]);
    });

    test('rename column', () {
      process('CREATE TABLE original (a INTEGER) /* comment */ STRICT;');
      process('ALTER TABLE original RENAME COLUMN a TO b;');

      expect(buffer.definitions, {
        'original': 'CREATE TABLE original (b INTEGER) /* comment */ STRICT;',
      });
    });

    test("rename column that doesn't exist", () {
      process('CREATE TABLE original (a INTEGER) /* comment */ STRICT;');
      expect(processWithErrors('ALTER TABLE original RENAME COLUMN c TO b;'), [
        analysisErrorWith(lexeme: 'c'),
      ]);
    });

    test("rename column conflict", () {
      process('CREATE TABLE original (a INTEGER, b INTEGER) STRICT;');
      expect(processWithErrors('ALTER TABLE original RENAME COLUMN a TO b;'), [
        analysisErrorWith(lexeme: 'b'),
      ]);
    });

    test('add column', () {
      process('CREATE TABLE original (a INTEGER);');
      process('ALTER TABLE original ADD COLUMN b TEXT NOT NULL;');
      expect(buffer.definitions, {
        'original': 'CREATE TABLE original (a INTEGER, b TEXT NOT NULL);',
      });
    });

    test('add column with indent', () {
      process('''
CREATE TABLE original (
  a INTEGER,
  b TEXT
);
''');
      process('ALTER TABLE original ADD COLUMN c TEXT NOT NULL;');
      expect(buffer.definitions, {
        'original': '''
CREATE TABLE original (
  a INTEGER,
  b TEXT,
  c TEXT NOT NULL
);''',
      });
    });

    test('drop column', () {
      process('''
CREATE TABLE tbl (
  a INTEGER NOT NUlL,
  -- this is another column definition to be removed
  b TEXT
) /* this comment should not be removed */;
''');

      process('ALTER TABLE tbl DROP COLUMN b;');

      expect(buffer.definitions, {
        'tbl': '''
CREATE TABLE tbl (
  a INTEGER NOT NUlL
) /* this comment should not be removed */;''',
      });
    });

    test('alter column', () {
      process('''
CREATE TABLE tbl (
  a INTEGER
);
''');

      process('ALTER TABLE tbl ALTER COLUMN a SET NOT NULL;');
      expect(buffer.definitions, {
        'tbl': '''
CREATE TABLE tbl (
  a INTEGER NOT NULL
);''',
      });

      process('ALTER TABLE tbl ALTER COLUMN a DROP NOT NULL;');
      expect(buffer.definitions, {
        'tbl': '''
CREATE TABLE tbl (
  a INTEGER
);''',
      });
    });

    test('drop column that does not exist', () {
      process('CREATE TABLE original (a INTEGER, b INTEGER) STRICT;');
      expect(processWithErrors('ALTER TABLE original DROP COLUMN c;'), [
        analysisErrorWith(lexeme: 'c'),
      ]);
    });

    test('drop only column', () {
      process('CREATE TABLE original (a INTEGER);');
      expect(processWithErrors('ALTER TABLE original DROP COLUMN a;'), [
        analysisErrorWith(
          lexeme: 'DROP COLUMN a',
          message: "Can't delete only remaining column in table",
        ),
      ]);
    });

    group('add constraint', () {
      test('no existing constraint', () {
        process('CREATE TABLE original (a INTEGER);');
        process('ALTER TABLE original ADD CHECK (a >= 0);');

        expect(buffer.definitions, {
          'original': 'CREATE TABLE original (a INTEGER, CHECK (a >= 0));',
        });
      });

      test('existing table constraint', () {
        process(
          'CREATE TABLE original (a INTEGER, CONSTRAINT smaller_zero CHECK (a < 0));',
        );
        process(
          'ALTER TABLE original ADD CONSTRAINT check_constraint CHECK (a >= 0);',
        );

        expect(buffer.definitions, {
          'original':
              'CREATE TABLE original (a INTEGER, CONSTRAINT smaller_zero CHECK (a < 0), CONSTRAINT check_constraint CHECK (a >= 0));',
        });
      });

      test('existing column constraint', () {
        process(
          'CREATE TABLE original (a INTEGER CONSTRAINT smaller_zero CHECK (a < 0));',
        );
        process('ALTER TABLE original ADD CHECK (a >= 0);');

        expect(buffer.definitions, {
          'original':
              'CREATE TABLE original (a INTEGER CONSTRAINT smaller_zero CHECK (a < 0), CHECK (a >= 0));',
        });
      });

      group('constraint name already exists', () {
        test('in column', () {
          process(
            'CREATE TABLE original (a INTEGER CONSTRAINT check_constraint CHECK (id > 0));',
          );

          expect(
            processWithErrors(
              'ALTER TABLE original ADD CONSTRAINT check_constraint CHECK (a >= 0);',
            ),
            [
              analysisErrorWith(
                type: AnalysisErrorType.other,
                lexeme: 'ADD CONSTRAINT check_constraint CHECK (a >= 0)',
                message: 'constraint check_constraint already exists',
              ),
            ],
          );
        });

        test('in table', () {
          process(
            'CREATE TABLE original (a INTEGER, CONSTRAINT check_constraint CHECK (a >=0));',
          );
          expect(
            processWithErrors(
              'ALTER TABLE original ADD CONSTRAINT check_constraint CHECK (a >= 0);',
            ),
            [
              analysisErrorWith(
                type: AnalysisErrorType.other,
                lexeme: 'ADD CONSTRAINT check_constraint CHECK (a >= 0)',
                message: 'constraint check_constraint already exists',
              ),
            ],
          );
        });
      });
    });

    group("drop constraint", () {
      test("table constraint", () {
        process(
          'CREATE TABLE original (a INTEGER, CONSTRAINT check_constraint CHECK (a > 0));',
        );
        process('ALTER TABLE original DROP CONSTRAINT check_constraint;');

        expect(buffer.definitions, {
          'original': 'CREATE TABLE original (a INTEGER);',
        });
      });

      test("check", () {
        process(
          'CREATE TABLE original (a INTEGER CONSTRAINT check_constraint CHECK (a > 0));',
        );
        process('ALTER TABLE original DROP CONSTRAINT check_constraint;');

        expect(buffer.definitions, {
          'original': 'CREATE TABLE original (a INTEGER );',
        });
      });

      test("not null", () {
        process(
          'CREATE TABLE original (a INTEGER CONSTRAINT not_null NOT NULL);',
        );
        process('ALTER TABLE original DROP CONSTRAINT not_null;');

        expect(buffer.definitions, {
          'original': 'CREATE TABLE original (a INTEGER );',
        });
      });

      test("multiple", () {
        process(
          'CREATE TABLE original (a INTEGER, CONSTRAINT check_constraint CHECK (a > 0), CHECK (a != 5));',
        );
        process('ALTER TABLE original DROP CONSTRAINT check_constraint;');

        expect(buffer.definitions, {
          'original': 'CREATE TABLE original (a INTEGER, CHECK (a != 5));',
        });
      });

      test("name doesn't exists", () {
        process(
          'CREATE TABLE original (a INTEGER CONSTRAINT not_null NOT NULL, CHECK (a >=0));',
        );
        expect(
          processWithErrors(
            'ALTER TABLE original DROP CONSTRAINT check_constraint;',
          ),
          [
            analysisErrorWith(
              type: AnalysisErrorType.other,
              lexeme: 'DROP CONSTRAINT check_constraint',
              message: 'no such constraint: check_constraint',
            ),
          ],
        );
      });

      test("may not be dropped", () {
        process(
          'CREATE TABLE original (a INTEGER CONSTRAINT unique_constraint UNIQUE, CONSTRAINT primary_constraint PRIMARY KEY (a));',
        );

        // check column constraint
        expect(
          processWithErrors(
            'ALTER TABLE original DROP CONSTRAINT unique_constraint;',
          ),
          [
            analysisErrorWith(
              type: AnalysisErrorType.other,
              lexeme: 'CONSTRAINT unique_constraint UNIQUE',
              message: 'constraint may not be dropped: unique_constraint',
            ),
          ],
        );

        // check table constraint
        expect(
          processWithErrors(
            'ALTER TABLE original DROP CONSTRAINT primary_constraint;',
          ),
          [
            analysisErrorWith(
              type: AnalysisErrorType.other,
              lexeme: 'CONSTRAINT primary_constraint PRIMARY KEY (a)',
              message: 'constraint may not be dropped: primary_constraint',
            ),
          ],
        );
      });
    });
  });
}
