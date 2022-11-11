import 'package:drift_dev/src/analysis/options.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

const _options = DriftOptions.defaults(modules: [SqlModule.fts5]);

void main() {
  group('reports error', () {
    test('for missing content table', () async {
      final state = TestBackend.inTest({
        'a|lib/main.drift': '''
CREATE VIRTUAL TABLE fts USING fts5(a, c, content=tbl);
''',
      }, options: _options);

      final result = await state.analyze('package:a/main.drift');
      expect(result.allErrors, [
        isDriftError('Could not find referenced content table: '
                '`tbl` could not be found in any import.')
            .withSpan('content=tbl'),
      ]);
    });

    test('for invalid rowid of content table', () async {
      final state = TestBackend.inTest({
        'a|lib/main.drift': '''
CREATE TABLE tbl (a, b, c, my_pk INTEGER PRIMARY KEY);

CREATE VIRTUAL TABLE fts USING fts5(a, c, content=tbl, content_rowid=d);
''',
      }, options: _options);

      final result = await state.analyze('package:a/main.drift');
      expect(result.allErrors, [
        isDriftError('Invalid content rowid, `d` not found in `tbl`')
            .withSpan('content_rowid=d'),
      ]);
    });

    test('when referencing an unknown column', () async {
      final state = TestBackend.inTest({
        'a|lib/main.drift': '''
CREATE TABLE tbl (a, b, c, d INTEGER PRIMARY KEY);

CREATE VIRTUAL TABLE fts USING fts5(e, c, content=tbl, content_rowid=d);
''',
      }, options: _options);

      final result = await state.analyze('package:a/main.drift');
      expect(result.allErrors,
          [isDriftError('The content table has no column `e`.').withSpan('e')]);
    });
  });

  test('finds referenced table', () async {
    final state = TestBackend.inTest({
      'a|lib/main.drift': '''
CREATE TABLE tbl (a, b, c, d INTEGER PRIMARY KEY);

CREATE VIRTUAL TABLE fts USING fts5(a, c, content=tbl, content_rowid=d);
CREATE VIRTUAL TABLE fts2 USING fts5(a, c, content=tbl, content_rowid=rowid);
''',
    }, options: _options);

    final result = await state.analyze('package:a/main.drift');
    expect(result.allErrors, isEmpty);
    final tables = result.analyzedElements.toList();

    expect(tables, hasLength(3));
    expect(tables[1].references, contains(tables[0]));
    expect(tables[2].references, contains(tables[0]));
  });
}
