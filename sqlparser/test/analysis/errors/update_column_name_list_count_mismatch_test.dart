import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../data.dart';
import 'utils.dart';

void main() {
  late SqlEngine engine;

  setUp(() {
    engine = SqlEngine();
    engine.registerTableFromSql('''
      CREATE TABLE foo (
        a INTEGER NOT NULL,
        b INTEGER NOT NULL
      );
    ''');
  });

  group("using column-name-list and tuple in update", () {
    test('reports error if they have different sizes', () {
      engine
          .analyze("UPDATE foo SET (a, b) = (1);")
          .expectError('(1)', type: AnalysisErrorType.cteColumnCountMismatch);
      engine
          .analyze("UPDATE foo SET (a) = (1,2);")
          .expectError('(1,2)', type: AnalysisErrorType.cteColumnCountMismatch);
    });
    test('reports no error if they have same sizes', () {
      engine.analyze("UPDATE foo SET (a, b) = (1,2);").expectNoError();
    });
  });

  group("using column-name-list and values in update", () {
    test('reports error if they have different sizes', () {
      engine.analyze("UPDATE foo SET (a, b) = (VALUES(1));").expectError(
          "(VALUES(1))",
          type: AnalysisErrorType.cteColumnCountMismatch);
      engine.analyze("UPDATE foo SET (a) = (VALUES(1,2));").expectError(
          "(VALUES(1,2))",
          type: AnalysisErrorType.cteColumnCountMismatch);
    });

    test('reports no error if they have same sizes', () {
      engine.analyze("UPDATE foo SET (a, b) = (VALUES(1,2));").expectNoError();
    });
  });

  group("using column-name-list and subquery in update", () {
    test('reports error if they have different sizes', () {
      engine.analyze("UPDATE foo SET (a, b) = (SELECT 1);").expectError(
          '(SELECT 1)',
          type: AnalysisErrorType.cteColumnCountMismatch);
      engine.analyze("UPDATE foo SET (a) = (SELECT 1,2);").expectError(
          '(SELECT 1,2)',
          type: AnalysisErrorType.cteColumnCountMismatch);
      engine
          .analyze(
              "UPDATE foo SET (a, b) = (SELECT b FROM foo as f WHERE f.a=a);")
          .expectError('(SELECT b FROM foo as f WHERE f.a=a)',
              type: AnalysisErrorType.cteColumnCountMismatch);
    });

    test('reports no error if they have same sizes', () {
      engine.analyze("UPDATE foo SET (a, b) = (SELECT 1,2);").expectNoError();
      engine
          .analyze(
              "UPDATE foo SET (a, b) = (SELECT b, a FROM foo as f WHERE f.a=a);")
          .expectNoError();
    });
  });
}
