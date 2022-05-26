import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import 'data.dart';

void main() {
  test('allows unqualified references to aliased table', () {
    final engine = SqlEngine()..registerTable(demoTable);
    final result = engine.analyze('SELECT * FROM demo d WHERE id');

    expect(result.errors, isEmpty);
  });

  test('does not allow references with wrong alias', () {
    final engine = SqlEngine()..registerTable(demoTable);
    final result = engine.analyze('SELECT * FROM demo d WHERE demo.id = 0');

    expect(result.errors, hasLength(1));
    expect(
      result.errors.single,
      isA<AnalysisError>()
          .having((e) => e.span?.text, 'span.text', 'demo.id')
          .having(
              (e) => e.type, 'type', AnalysisErrorType.referencedUnknownTable),
    );
  });

  test('does not register the same result set multiple times', () {
    final engine = SqlEngine(EngineOptions(useDriftExtensions: true))
      ..registerTableFromSql('''
        CREATE TABLE with_defaults (
          a TEXT DEFAULT 'something',
          b INT UNIQUE
        );
      ''')
      ..registerTableFromSql('''
        CREATE TABLE with_constraints (
          a TEXT,
          b INT NOT NULL,
          c FLOAT(10, 2),

          FOREIGN KEY (a, b) REFERENCES with_defaults (a, b)
        );
      ''');

    final result = engine.analyze(r'''
      SELECT d.*, c.** FROM with_defaults d
      LEFT OUTER JOIN with_constraints c
        ON d.a = c.a AND d.b = c.b
      WHERE $predicate;
    ''');

    final scope = result.root.statementScope;
    expect(scope.resultSets, hasLength(2));
  });
}
