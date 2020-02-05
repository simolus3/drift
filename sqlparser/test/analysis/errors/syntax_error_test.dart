// tests for syntax errors revealed during static analysis.

import 'package:sqlparser/src/analysis/analysis.dart';
import 'package:sqlparser/src/engine/sql_engine.dart';
import 'package:test/test.dart';

import '../data.dart';

void main() {
  test('DO UPDATE clause without conflict target', () {
    final engine = SqlEngine()..registerTable(demoTable);
    final result = engine.analyze('INSERT INTO demo VALUES (?, ?)  '
        'ON CONFLICT DO UPDATE SET id = 3;');

    expect(result.errors, [
      const TypeMatcher<AnalysisError>()
          .having((e) => e.type, 'type', AnalysisErrorType.synctactic)
          .having((e) => e.message, 'message',
              contains('Expected a conflict clause'))
    ]);
  });
}
