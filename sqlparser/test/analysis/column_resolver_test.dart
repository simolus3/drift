import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import 'data.dart';
import 'errors/utils.dart';

void main() {
  late SqlEngine engine;

  setUp(() {
    engine = SqlEngine(EngineOptions(version: SqliteVersion.v3_35));
    engine.registerTable(demoTable);
  });

  group('CREATE TRIGGER statements', () {
    group('delete', () {
      test('can use OLD references', () {
        final context = engine.analyze('''
CREATE TRIGGER my_trigger BEFORE DELETE ON demo BEGIN
  SELECT * FROM old;
END;
        ''');

        expect(context.errors, isEmpty);
      });

      test("can't use NEW references", () {
        final context = engine.analyze('''
CREATE TRIGGER my_trigger BEFORE DELETE ON demo BEGIN
  SELECT * FROM new;
END;
        ''');

        expect(
          context.errors,
          contains(const TypeMatcher<AnalysisError>()
              .having((e) => e.type, 'type',
                  AnalysisErrorType.referencedUnknownTable)
              .having((e) => e.span!.text, 'span.text', 'new')),
        );
      });
    });

    group('insert', () {
      test('can use NEW references', () {
        final context = engine.analyze('''
CREATE TRIGGER my_trigger BEFORE INSERT ON demo BEGIN
  SELECT * FROM new;
END;
        ''');

        expect(context.errors, isEmpty);
      });

      test("can't use OLD references", () {
        final context = engine.analyze('''
CREATE TRIGGER my_trigger BEFORE INSERT ON demo BEGIN
  SELECT * FROM old;
END;
        ''');

        expect(
          context.errors,
          contains(const TypeMatcher<AnalysisError>()
              .having((e) => e.type, 'type',
                  AnalysisErrorType.referencedUnknownTable)
              .having((e) => e.span!.text, 'span.text', 'old')),
        );
      });
    });

    test('update can use NEW and OLD references', () {
      final context = engine.analyze('''
CREATE TRIGGER my_trigger BEFORE UPDATE ON demo BEGIN
  SELECT * FROM new;
  INSERT INTO old VALUES (1, 'foo');
END;
      ''');
      expect(context.errors, isEmpty);
    });

    test('can refer to column in UPDATE OF', () {
      final context = engine.analyze('''
CREATE TRIGGER my_trigger BEFORE UPDATE OF content ON DEMO BEGIN
  SELECT * FROM demo;
END;
      ''');

      expect(context.errors, isEmpty);
    });

    test('can refer to column in UPDATE OF', () {
      final context = engine.analyze('''
CREATE TRIGGER my_trigger BEFORE DELETE ON DEMO WHEN id < 10 BEGIN
  SELECT * FROM demo;
END;
      ''');

      expect(context.errors, isEmpty);
    });
  });

  test("DO UPDATE action in upsert can refer to 'exluded'", () {
    final context = engine.analyze('''
INSERT INTO demo VALUES (?, ?)
  ON CONFLICT (id) DO UPDATE SET
    content = content || excluded.content;
    ''');

    expect(context.errors, isEmpty);
  });

  test('columns from values statement', () {
    final context = engine.analyze("VALUES ('foo', 3), ('bar', 5)");

    expect(context.errors, isEmpty);
    final columns = (context.root as ResultSet).resolvedColumns!;

    expect(columns.map((e) => e.name), ['Column1', 'Column2']);
    expect(columns.map((e) => context.typeOf(e).type?.type),
        [BasicType.text, BasicType.int]);
  });

  test('columns from nested VALUES', () {
    final context = engine.analyze('SELECT Column1 FROM (VALUES (3))');

    expect(context.errors, isEmpty);
  });

  test('gracefully handles tuples of different lengths in VALUES', () {
    final context = engine.analyze("VALUES ('foo', 3), ('bar')");

    expect(context.errors, isNotEmpty);
    final columns = (context.root as ResultSet).resolvedColumns!;

    expect(columns.map((e) => e.name), ['Column1', 'Column2']);
    expect(columns.map((e) => context.typeOf(e).type?.type),
        [BasicType.text, BasicType.int]);
  });

  test('handles update statement with from clause', () {
    // Example from here: https://www.sqlite.org/lang_update.html#upfrom
    engine
      ..registerTableFromSql('''
      CREATE TABLE inventory (
        itemId INTEGER PRIMARY KEY,
        quantity INTEGER NOT NULL DEFAULT 0,
      );
    ''')
      ..registerTableFromSql('''
      CREATE TABLE sales (
        itemId INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
      );
    ''');

    final result = engine.analyze('''
      UPDATE inventory
        SET quantity = quantity - daily.amt
        FROM (SELECT sum(quantity) AS amt, itemId FROM sales GROUP BY 2)
          AS daily
        WHERE inventory.itemId = daily.itemId;
    ''');

    expect(result.errors, isEmpty);
  });

  group('resolves RETURNING clause', () {
    test('for simple inserts', () {
      final result = engine
          .analyze("INSERT INTO demo (content) VALUES ('hi') RETURNING *;");
      final returning = (result.root as InsertStatement).returnedResultSet;

      expect(returning, isNotNull);
      expect(returning!.resolvedColumns!.map((e) => e.name), ['id', 'content']);
    });

    test('for custom expressions', () {
      final result = engine.analyze("INSERT INTO demo (content) VALUES ('hi') "
          'RETURNING content || content AS x;');
      final returning = (result.root as InsertStatement).returnedResultSet!;

      expect(returning.resolvedColumns!.map((e) => e.name), ['x']);
    });

    test('star does not include other tables', () {
      final result = engine.analyze('''
        UPDATE demo SET content = ''
          FROM (SELECT * FROM demo) AS old
          RETURNING *;
      ''');
      final returning = (result.root as UpdateStatement).returnedResultSet!;
      expect(returning.resolvedColumns!.map((e) => e.name), ['id', 'content']);
    });

    test('can refer to columns from other tables', () {
      final result = engine.analyze('''
        UPDATE demo SET content = ''
          FROM (SELECT * FROM demo) AS old
          RETURNING old.id, old.content;
      ''');

      expect(result.errors, isEmpty);
    });
  });

  test('reports error when using star wihout tables', () {
    final result = engine.analyze('SELECT 1, 2, *;');

    expect(result.errors, hasLength(1));
    expect(
      result.errors.single,
      isA<AnalysisError>()
          .having(
              (e) => e.type, 'type', AnalysisErrorType.starColumnWithoutTable)
          .having((e) => e.source?.span?.text, 'source.span?.text', '*'),
    );
  });

  group('resolves target columns of INSERT', () {
    test('for regular tables', () {
      final root = engine.analyze('INSERT INTO demo VALUES (?, ?)').root
          as InsertStatement;

      expect(root.resolvedTargetColumns, hasLength(2));
    });

    test('when there are generated columns', () {
      engine.registerTableFromSql('''
        CREATE TABLE x (
          a TEXT NOT NULL,
          b TEXT GENERATED ALWAYS AS (a)
        );
      ''');

      final root =
          engine.analyze('INSERT INTO x VALUES (?, ?)').root as InsertStatement;

      expect(root.resolvedTargetColumns, hasLength(1));
    });
  });

  test('does not allow a subquery in from to read outer values', () {
    final result = engine.analyze(
        'SELECT * FROM demo d1, (SELECT * FROM demo i WHERE i.id = d1.id) d2;');

    result.expectError('d1.id', type: AnalysisErrorType.referencedUnknownTable);
  });

  test('allows subquery expressions to read outer values', () {
    final result = engine.analyze('SELECT * FROM demo d1 WHERE '
        'EXISTS (SELECT * FROM demo i WHERE i.id = d1.id);');

    result.expectNoError();
  });
}
