import 'package:drift_dev/src/analyzer/errors.dart';
import 'package:drift_dev/src/analyzer/options.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../utils.dart';

const _moorFile = '''
CREATE TABLE foo (
  id INTEGER NOT NULL PRIMARY KEY,
  content TEXT NOT NULL UNIQUE,
  content2 TEXT NOT NULL UNIQUE
);

query: INSERT INTO foo VALUES (?, ?, ?)
  ON CONFLICT (content) DO NOTHING
  ON CONFLICT (content2) DO UPDATE SET content2 = 'duplicate';
        ''';

void main() {
  test('does not support newer sqlite features by default', () async {
    final state = TestState.withContent(
      const {
        'a|lib/main.moor': _moorFile,
      },
      enableAnalyzer: false,
    );

    final file = await state.analyze('package:a/main.moor');
    expect(file.errors.errors, hasLength(1));
    expect(
      file.errors.errors.single,
      isA<ErrorInMoorFile>().having(
        (e) => e.message,
        'message',
        allOf(
          contains('require sqlite version 3.35 or later'),
          contains('You can change the sqlite version with build options.'),
        ),
      ),
    );
  });

  test('supports newer sqlite features', () async {
    final state = TestState.withContent(
      const {
        'a|lib/main.moor': _moorFile,
      },
      enableAnalyzer: false,
      options: const MoorOptions.defaults(
        sqliteAnalysisOptions: SqliteAnalysisOptions(
          version: SqliteVersion.v3_35,
        ),
      ),
    );

    final file = await state.analyze('package:a/main.moor');
    expect(file.errors.errors, isEmpty);
  });
}
