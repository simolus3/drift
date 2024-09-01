import 'package:sqlparser/src/analysis/analysis.dart';
import 'package:sqlparser/src/engine/sql_engine.dart';
import 'package:test/test.dart';

import '../data.dart';
import 'utils.dart';

void main() {
  final engine = SqlEngine()
    ..registerTable(demoTable)
    ..registerViewFromSql('CREATE VIEW my_view AS SELECT 1 as c;');

  test('does not allow INSTEAD OF on tables', () {
    final result = engine.analyze('''
      CREATE TRIGGER my_trigger INSTEAD OF INSERT ON demo BEGIN
        SELECT 1;
      END;
    ''');

    result.expectError(
      'demo',
      type: AnalysisErrorType.invalidTriggerMode,
      message: contains('only allowed on views'),
    );

    engine.analyze('''
      CREATE TRIGGER my_trigger INSTEAD OF INSERT ON my_view BEGIN
        SELECT 1;
      END;
    ''').expectNoError();
  });

  test('does not allow AFTER on views', () {
    final result = engine.analyze('''
      CREATE TRIGGER my_trigger AFTER INSERT ON my_view BEGIN
        SELECT 1;
      END;
    ''');

    result.expectError(
      'my_view',
      type: AnalysisErrorType.invalidTriggerMode,
      message: contains('Only `INSTEAD OF` triggers are allowed for views'),
    );
  });
}
