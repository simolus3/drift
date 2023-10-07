import 'package:drift/drift.dart';
import 'package:drift_dev/src/analysis/options.dart';
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:drift_dev/src/writer/import_manager.dart';
import 'package:drift_dev/src/writer/schema_version_writer.dart';
import 'package:drift_dev/src/writer/writer.dart';
import 'package:test/test.dart';

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
}
