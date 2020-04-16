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
              .having((e) => e.span.text, 'span.text', 'new')),
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
              .having((e) => e.span.text, 'span.text', 'old')),
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
    final columns = (context.root as ResultSet).resolvedColumns;

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
    final columns = (context.root as ResultSet).resolvedColumns;

    expect(columns.map((e) => e.name), ['Column1', 'Column2']);
    expect(columns.map((e) => context.typeOf(e).type?.type),
        [BasicType.text, BasicType.int]);
  });
}
