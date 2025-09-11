import 'package:drift_dev/src/analysis/options.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

const _content = {
  'a|lib/main.drift': '''
CREATE TABLE foo (
  id INTEGER NOT NULL PRIMARY KEY,
  content TEXT NOT NULL UNIQUE
);

query: SELECT group_concat(content ORDER BY id) FROM foo;
        ''',
};

void main() {
  test('does not support newer sqlite features by default', () async {
    final state = await TestBackend.inTest(_content);

    final file = await state.analyze('package:a/main.drift');
    expect(
      file.allErrors,
      [
        isDriftError(
          allOf(
            contains('require sqlite 3.44 or later'),
            contains(
                'You can change the assumed sqlite version with build options.'),
          ),
        ),
      ],
    );
  });

  test('supports newer sqlite features', () async {
    final state = await TestBackend.inTest(
      _content,
      options: const DriftOptions.defaults(
        sqliteAnalysisOptions: SqliteAnalysisOptions(
          version: SqliteVersion.v3_50,
        ),
      ),
    );

    await state.analyze('package:a/main.drift');
    state.expectNoErrors();
  });
}
