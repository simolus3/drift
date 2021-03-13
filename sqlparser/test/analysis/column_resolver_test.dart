import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import 'data.dart';

void main() {
  final engine = SqlEngine();
  engine.registerTable(demoTable);

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
    engine..registerTableFromSql('''
      CREATE TABLE inventory (
        itemId INTEGER PRIMARY KEY,
        quantity INTEGER NOT NULL DEFAULT 0,
      );
    ''')..registerTableFromSql('''
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
}
