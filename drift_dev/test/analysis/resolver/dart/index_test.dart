import 'package:build_test/build_test.dart';
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:test/test.dart';

import '../../../utils.dart';
import '../../test_utils.dart';

void main() {
  test('resolves index', () async {
    final backend = await TestBackend.inTest({
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
    final backend = await TestBackend.inTest({
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

  group('SQL', () {
    test('can create index', () async {
      final results = await emulateDriftBuild(
        inputs: {
          'a|lib/a.dart': '''
import 'package:drift/drift.dart';

@TableIndex.sql('CREATE INDEX my_index ON my_table (a) WHERE a > 10')
class MyTable extends Table {
  IntColumn get a => integer()();
}
''',
        },
        modularBuild: true,
        logger: loggerThat(neverEmits(anything)),
      );

      checkOutputs({
        'a|lib/a.drift.dart': decodedMatches(contains(
            "i0.Index('my_index', 'CREATE INDEX my_index ON my_table (a) WHERE a > 10')")),
      }, results.dartOutputs, results.writer);
    });

    test('warns on mismatching tables', () async {
      final backend = await TestBackend.inTest({
        'a|lib/a.dart': '''
import 'package:drift/drift.dart';

@TableIndex.sql('CREATE INDEX my_index ON other_table (a);')
class MyTable extends Table {
  IntColumn get a => integer()();
}

class OtherTable extends Table {
  IntColumn get a => integer()();
}
''',
      });

      final file = await backend.analyze('package:a/a.dart');
      expect(file.allErrors, [
        isDriftError(
            'This index was applied to `MyTable` in Dart, but references `other_table` in SQL.')
      ]);
    });

    test('reports SQL errors', () async {
      final backend = await TestBackend.inTest({
        'a|lib/a.dart': '''
import 'package:drift/drift.dart';

@TableIndex.sql('CREATE INDEX my_index ON my_table (a, b);')
class MyTable extends Table {
  IntColumn get a => integer()();
}
''',
      });

      final file = await backend.analyze('package:a/a.dart');
      expect(file.allErrors, [isDriftError('b: Unknown column.')]);
    });
  });
}
