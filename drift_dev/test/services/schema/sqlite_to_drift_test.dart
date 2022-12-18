import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:drift_dev/src/services/schema/sqlite_to_drift.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  test('can extract elements from database', () async {
    final database = sqlite3.openInMemory()
      ..execute('CREATE TABLE foo (id INTEGER PRIMARY KEY, bar TEXT);')
      ..execute('CREATE INDEX my_idx ON foo (bar)')
      ..execute('CREATE VIEW my_view AS SELECT bar FROM foo')
      ..execute('CREATE TRIGGER my_trigger AFTER UPDATE ON foo BEGIN '
          'UPDATE foo SET bar = old.bar; '
          'END;');
    addTearDown(database.dispose);

    final elements = await extractDriftElementsFromDatabase(database);
    expect(
      elements,
      unorderedEquals([
        isA<DriftTable>().having((e) => e.schemaName, 'schemaName', 'foo'),
        isA<DriftIndex>().having((e) => e.schemaName, 'schemaName', 'my_idx'),
        isA<DriftView>().having((e) => e.schemaName, 'schemaName', 'my_view'),
        isA<DriftTrigger>()
            .having((e) => e.schemaName, 'schemaName', 'my_trigger'),
      ]),
    );
  });

  test('ignores internal tables', () async {
    final database = sqlite3.openInMemory()
      ..execute('CREATE TABLE my_table (id INTEGER PRIMARY KEY AUTOINCREMENT)')
      ..execute('CREATE VIRTUAL TABLE foo USING fts5(x,y, z);');

    addTearDown(database.dispose);

    final elements = await extractDriftElementsFromDatabase(database);
    expect(
      elements,
      unorderedEquals([
        isA<DriftTable>().having((e) => e.schemaName, 'schemaName', 'my_table'),
        isA<DriftTable>().having((e) => e.schemaName, 'schemaName', 'foo'),
      ]),
    );
  });
}
