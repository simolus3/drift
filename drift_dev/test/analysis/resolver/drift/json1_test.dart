import 'package:drift_dev/src/analysis/options.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  test('json_extract result type is inferred by context', () async {
    final state = await TestBackend.inTest(
      {
        'foo|lib/a.drift': r'''
CREATE TABLE IF NOT EXISTS foo (
  bar TEXT NOT NULL,
  baz TEXT NOT NULL
);

insertFoo(:foo_jsons AS TEXT):
INSERT INTO foo(bar, baz)
SELECT json_extract(value, '$.bar'), json_extract(value, '$.baz')
FROM json_each(:foo_jsons);
      ''',
      },
      options: const DriftOptions.defaults(
        modules: [SqlModule.json1],
        sqliteAnalysisOptions:
            SqliteAnalysisOptions(version: SqliteVersion.v3_39),
      ),
    );

    await state.analyze('package:foo/a.drift');

    state.expectNoErrors();
  });
}
