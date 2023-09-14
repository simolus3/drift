import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  test('resolves index', () async {
    final backend = TestBackend.inTest({
      'a|lib/a.dart': '''
import 'package:drift/drift.dart';

@TableIndex(columns: {#a}, name: 'tbl_a')
@TableIndex(columns: {#b, #c}, name: 'tbl_bc', unique: true)
class MyTable extends Table {
  IntColumn get a => integer()();
  TextColumn get b => text()();
  TextColumn get c => text()();
}
''',
    });

    final file = await backend.analyze('package:a/a.dart');
    backend.expectNoErrors();

    final elements = file.analyzedElements;
    final table = elements.whereType<DriftTable>().first;

    final indexA = file.analysis[file.id('tbl_a')]!.result as DriftIndex;
    final indexBC = file.analysis[file.id('tbl_bc')]!.result as DriftIndex;

    expect(indexA.table, table);
    expect(indexA.unique, false);
    expect(indexA.indexedColumns, [table.columnBySqlName['a']]);

    expect(indexBC.table, table);
    expect(indexBC.unique, true);
    expect(indexBC.indexedColumns, [
      table.columnBySqlName['b'],
      table.columnBySqlName['c'],
    ]);
  });

  test('warns about missing columns', () async {
    final backend = TestBackend.inTest({
      'a|lib/a.dart': '''
import 'package:drift/drift.dart';

@TableIndex(columns: {#foo}, name: 'tbl_a')
class MyTable extends Table {
  IntColumn get a => integer()();
}
''',
    });

    final file = await backend.analyze('package:a/a.dart');
    expect(file.allErrors, [
      isDriftError(
          'Column `foo`, referenced in index `tbl_a`, was not found in the table.')
    ]);
  });
}
