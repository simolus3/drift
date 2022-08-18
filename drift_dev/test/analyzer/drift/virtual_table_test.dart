import 'package:drift_dev/src/analyzer/options.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  test('supports virtual tables across moor files', () async {
    final state = TestState.withContent(
      {
        'a|lib/table.moor': '''
CREATE TABLE example_table (
    json_column TEXT,
    name TEXT,
    content TEXT
);

CREATE VIRTUAL TABLE example_table_search
    USING fts5(
        name, content, content='example_table', content_rowid='rowid'
    );
''',
        'a|lib/queries.moor': '''
import 'table.moor';

exampleSearch: SELECT example_table.**, s.* FROM example_table
    INNER JOIN (
        SELECT rowid,
            highlight(example_table_search, 0, '[match]', '[match]') name,
            snippet(example_table_search, 1, '[match]', '[match]', '...', 10) content,
            bm25(example_table_search) AS rank
        FROM example_table_search WHERE example_table_search MATCH :search
    ) AS s
    ON s.rowid = example_table.rowid;
''',
      },
      options: const DriftOptions.defaults(modules: [SqlModule.fts5]),
    );
    addTearDown(state.close);

    final result = await state.analyze('package:a/queries.moor');
    expect(result.errors.errors, isEmpty);
  });

  test('query virtual tables with unknown function', () async {
    final state = TestState.withContent(
      {
        'a|lib/table.moor': '''
CREATE TABLE example_table (
    json_column TEXT,
    name TEXT,
    content TEXT
);

CREATE VIRTUAL TABLE example_table_search
    USING fts5(
        name, content, content='example_table', content_rowid='rowid'
    );

exampleSearch: 
SELECT rowid, highlight(example_table_search, 0, '[match]', '[match]') name,
            snippet(example_table_search, 1, '[match]', '[match]', '...', 10) content,
            bm25(example_table_search) AS rank
        FROM example_table_search WHERE example_table_search MATCH simple_query(:search);
        ''',
      },
      options: const DriftOptions.defaults(modules: [SqlModule.fts5]),
    );
    addTearDown(state.close);
    final result = await state.analyze('package:a/table.moor');
    expect(result.errors.errors, hasLength(1));
    expect(result.errors.errors.single.message,
        contains('Function simple_query could not be found'));
  });
}
