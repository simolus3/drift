import 'package:sqlparser/src/analysis/analysis.dart';
import 'package:sqlparser/src/engine/sql_engine.dart';
import 'package:test/test.dart';

import '../data.dart';

void main() {
  test('does not report errors for RAISE used in triggers', () {
    final engine = SqlEngine();
    engine.registerTable(demoTable);
    final result = engine.analyze('''
      CREATE TRIGGER my_trigger AFTER INSERT ON demo BEGIN
        SELECT RAISE(FAIL, 'Not allowed');
      END;
    ''');

    expect(result.errors, isEmpty);
  });

  test('does not allow RAISE in top-level statements', () {
    final engine = SqlEngine();
    final result = engine.analyze("SELECT RAISE(FAIL, 'Not allowed');");

    expect(result.errors, hasLength(1));
    expect(
      result.errors.single,
      isA<AnalysisError>()
          .having((e) => e.type, 'type', AnalysisErrorType.raiseMisuse),
    );
  });
}
