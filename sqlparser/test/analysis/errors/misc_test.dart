import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../data.dart';
import 'utils.dart';

void main() {
  final engine = SqlEngine()..registerTable(demoTable);

  test('warns about multiple parameters with DISTINCT', () {
    engine
        .analyze("SELECT group_concat(DISTINCT content, '-') FROM demo")
        .expectError(
          'DISTINCT',
          type: AnalysisErrorType.distinctAggregateWithWrongParameterCount,
        );
  });

  group('illegal column names in alter table', () {
    void check(String sql, String errorLexeme) {
      engine
          .analyze(sql)
          .expectError(errorLexeme, type: AnalysisErrorType.alterRowIdColumn);
    }

    test('add', () {
      check('ALTER TABLE demo ADD COLUMN _rowid_ INTEGER NOT NULL', '_rowid_');
    });

    test('drop', () {
      check('ALTER TABLE demo DROP COLUMN oId', 'oId');
    });

    test('rename', () {
      check('ALTER TABLE demo RENAME COLUMN id TO rowid', 'rowid');
      check('ALTER TABLE demo RENAME COLUMN rowid TO id', 'rowid');
    });
  });
}
