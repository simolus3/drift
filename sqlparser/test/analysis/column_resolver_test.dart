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
}
