import 'package:drift/drift.dart' hide DriftDatabase;
import 'package:drift_dev/src/analysis/options.dart';
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:drift_dev/src/writer/import_manager.dart';
import 'package:drift_dev/src/writer/schema_version_writer.dart';
import 'package:drift_dev/src/writer/writer.dart';
import 'package:test/test.dart';

import '../analysis/test_utils.dart';

void main() {
  final fakeUri = Uri.parse('drift:hidden');

  DriftTable buildTable(String name) {
    return DriftTable(
      DriftElementId(fakeUri, name),
      DriftDeclaration(fakeUri, -1, ''),
      columns: [
        DriftColumn(
          sqlType: ColumnType.drift(DriftSqlType.int),
          nullable: false,
          nameInSql: 'foo',
          nameInDart: 'foo',
          declaration: DriftDeclaration(
            fakeUri,
            -1,
            '',
          ),
        ),
      ],
      baseDartName: name,
      nameOfRowClass: name.substring(0, 1).toUpperCase() + name.substring(1),
    );
  }

  String containsTableRegex(String name, {bool withSuffix = false}) =>
      'late final Shape\\d+ $name${withSuffix ? r'\w+' : ''} =';

  test('avoids conflict with getters in schema class', () async {
    final imports = LibraryImportManager();
    final writer = Writer(
      const DriftOptions.defaults(),
      generationOptions: GenerationOptions(imports: imports),
    );
    imports.linkToWriter(writer);

    final normalTable = buildTable('myFirstTable');

    final problemTables = [
      'database',
      'entities',
      'version',
      'stepByStepHelper',
      'runMigrationSteps',
    ].map(buildTable).toList();
    final secondaryProblemTables = problemTables
        .map((t) => '${t.baseDartName}Table')
        .map(buildTable)
        .toList();
    SchemaVersionWriter(
      [
        SchemaVersion(
          1,
          [normalTable],
          const {},
        ),
        SchemaVersion(
          2,
          [
            normalTable,
            ...problemTables,
            ...secondaryProblemTables,
          ],
          const {},
        ),
      ],
      writer.child(),
    ).write();

    final output = writer.writeGenerated();

    // Tables without conflicting names shouldn't be modified.
    expect(output, matches(containsTableRegex(normalTable.baseDartName)));

    // Tables that directly conflict with member names from VersionedSchema and
    // its superclasses should have their names modified and not appear with
    // their original name at all.
    for (final tableName in problemTables.map((t) => t.baseDartName)) {
      expect(
        output,
        isNot(matches(containsTableRegex(tableName))),
      );
      expect(output, matches(containsTableRegex(tableName, withSuffix: true)));
    }

    // Tables that conflict with modified table names should themselves be
    // modified to prevent the conflict. We can't check for nonexistence here
    // because the the entire point is the name conficts with an in-use table
    // name, so we only check for the existence of the doubly modified name.
    for (final tableName in secondaryProblemTables.map((t) => t.baseDartName)) {
      expect(output, matches(containsTableRegex(tableName, withSuffix: true)));
    }
  });

  test('can generate references between columns', () async {
    // Regression test for https://github.com/simolus3/drift/issues/3554
    final backend = await TestBackend.inTest({
      'a|lib/a.dart': r'''
import 'package:drift/drift.dart';
import 'package:drift/extensions/json1.dart';

class ComplexTable extends Table {
  @override
  String get tableName => 'complex_table';

  // A json column
  TextColumn get reference => text()();

 // extracts data from the reference column
  TextColumn get packageId =>
      text()
          .generatedAs(reference.jsonExtract<String>(r'$.package_id'), stored: true)();
}
''',
    });

    final results = await backend.analyze('package:a/a.dart');
    backend.expectNoErrors();

    final [table as DriftTable] = results.analyzedElements.toList();

    final imports = LibraryImportManager();
    final writer = Writer(
      const DriftOptions.defaults(),
      generationOptions: GenerationOptions(imports: imports),
    );
    imports.linkToWriter(writer);
    SchemaVersionWriter(
      [
        SchemaVersion(
          1,
          [table],
          const {},
        ),
        SchemaVersion(
          2,
          [table],
          const {},
        ),
      ],
      writer.child(),
    ).write();

    final output = writer.writeGenerated();

    // Writing the reference in jsonExtract should not write `reference`
    // directly, because that's not possible when extracting columns from the
    // table.
    expect(
      output,
      contains(
        "generatedAs: i1.GeneratedAs(i2.JsonExtensions("
        "(i0.VersionedTable.col<String>('reference'))"
        ").jsonExtract<String>(r'\$.package_id')",
      ),
    );
  });

  test('can write on create queries', () async {
    // Regression test for https://github.com/simolus3/drift/issues/3555
    final backend = await TestBackend.inTest({
      'a|lib/definitions.drift': r'''
create table if not exists __metadata(
  version int not null primary key
);

@create: insert into __metadata values (5) on conflict do nothing;
''',
      'a|lib/a.dart': '''
import 'package:drift/drift.dart';

@DriftDatabase(include: {'definitions.drift'})
class MyDatabase {}
''',
    });

    final results = await backend.analyze('package:a/a.dart');
    backend.expectNoErrors();
    final db = results.fileAnalysis!.resolvedDatabases.values.single;

    final imports = LibraryImportManager();
    final writer = Writer(
      const DriftOptions.defaults(),
      generationOptions: GenerationOptions(imports: imports),
    );
    imports.linkToWriter(writer);
    SchemaVersionWriter(
      [
        SchemaVersion(
          1,
          db.availableElements,
          const {},
        ),
        SchemaVersion(
          2,
          db.availableElements,
          const {},
        ),
      ],
      writer.child(),
    ).write();

    final output = writer.writeGenerated();
    expect(output, contains('VALUES (5) ON CONFLICT DO NOTHING'));
  });
}
