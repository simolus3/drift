import 'package:drift_dev/src/analyzer/options.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  // Regression test for https://github.com/simolus3/drift/issues/754
  test('supports fts5 tables with external content', () async {
    final state = TestState.withContent({
      'foo|lib/a.moor': '''
CREATE TABLE tbl(a INTEGER PRIMARY KEY, b TEXT, c TEXT);
CREATE VIRTUAL TABLE fts_idx USING fts5(b, c, content='tbl', content_rowid='a');

-- Triggers to keep the FTS index up to date.
CREATE TRIGGER tbl_ai AFTER INSERT ON tbl BEGIN
  INSERT INTO fts_idx(rowid, b, c) VALUES (new.a, new.b, new.c);
END;

CREATE TRIGGER tbl_ad AFTER DELETE ON tbl BEGIN
  INSERT INTO fts_idx(fts_idx, rowid, b, c) VALUES('delete', old.a, old.b, old.c);
END;

CREATE TRIGGER tbl_au AFTER UPDATE ON tbl BEGIN
  INSERT INTO fts_idx(fts_idx, rowid, b, c) VALUES('delete', old.a, old.b, old.c);
  INSERT INTO fts_idx(rowid, b, c) VALUES (new.a, new.b, new.c);
END;
      ''',
    }, options: const MoorOptions.defaults(modules: [SqlModule.fts5]));

    final result = await state.analyze('package:foo/a.moor');

    // The generator used to crash while analyzing, so consider the test passed
    // if it can analyze the file and sees that there aren't any errors.
    expect(result.errors.errors, isEmpty);
  });
}
