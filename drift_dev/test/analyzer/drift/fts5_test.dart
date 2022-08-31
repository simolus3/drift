import 'package:drift_dev/src/analyzer/errors.dart';
import 'package:drift_dev/src/analyzer/options.dart';
import 'package:test/test.dart';

import '../utils.dart';

const _options = DriftOptions.defaults(modules: [SqlModule.fts5]);

void main() {
  group('reports error', () {
    test('for missing content table', () async {
      final state = TestState.withContent({
        'a|lib/main.drift': '''
CREATE VIRTUAL TABLE fts USING fts5(a, c, content=tbl);
''',
      }, options: _options);
      addTearDown(state.close);

      final result = await state.analyze('package:a/main.drift');
      expect(result.errors.errors, [
        const TypeMatcher<ErrorInDriftFile>().having(
          (e) => e.message,
          'message',
          contains('Content table `tbl` could not be found'),
        ),
      ]);
    });

    test('for invalid rowid of content table', () async {
      final state = TestState.withContent({
        'a|lib/main.drift': '''
CREATE TABLE tbl (a, b, c, my_pk INTEGER PRIMARY KEY);

CREATE VIRTUAL TABLE fts USING fts5(a, c, content=tbl, content_rowid=d);
''',
      }, options: _options);
      addTearDown(state.close);

      final result = await state.analyze('package:a/main.drift');
      expect(result.errors.errors, [
        const TypeMatcher<ErrorInDriftFile>().having(
          (e) => e.message,
          'message',
          contains(
            'no column `d`, but this fts5 table is declared to use it as a row '
            'id',
          ),
        ),
      ]);
    });

    test('when referencing an unknown column', () async {
      final state = TestState.withContent({
        'a|lib/main.drift': '''
CREATE TABLE tbl (a, b, c, d INTEGER PRIMARY KEY);

CREATE VIRTUAL TABLE fts USING fts5(e, c, content=tbl, content_rowid=d);
''',
      }, options: _options);
      addTearDown(state.close);

      final result = await state.analyze('package:a/main.drift');
      expect(result.errors.errors, [
        const TypeMatcher<ErrorInDriftFile>().having(
          (e) => e.message,
          'message',
          contains('no column `e`, but this fts5 table references it'),
        ),
      ]);
    });
  });

  test('finds referenced table', () async {
    final state = TestState.withContent({
      'a|lib/main.drift': '''
CREATE TABLE tbl (a, b, c, d INTEGER PRIMARY KEY);

CREATE VIRTUAL TABLE fts USING fts5(a, c, content=tbl, content_rowid=d);
CREATE VIRTUAL TABLE fts2 USING fts5(a, c, content=tbl, content_rowid=rowid);
''',
    }, options: _options);
    addTearDown(state.close);

    final result = await state.analyze('package:a/main.drift');
    expect(result.errors.errors, isEmpty);
    final tables = result.currentResult!.declaredTables.toList();

    expect(tables, hasLength(3));
    expect(tables[1].references, contains(tables[0]));
    expect(tables[2].references, contains(tables[0]));
  });
}
