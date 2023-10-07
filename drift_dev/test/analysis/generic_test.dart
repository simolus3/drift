@Tags(['analyzer'])
import 'package:drift/drift.dart' show DriftSqlType;
import 'package:drift_dev/src/analysis/driver/state.dart';
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('handles cyclic imports', () async {
    final state = TestBackend.inTest({
      'a|lib/entry.dart': '''
import 'package:drift/drift.dart';

class Foos extends Table {
  IntColumn get id => integer().autoIncrement()();
}

@DriftDatabase(include: {'db.drift'}, tables: [Foos])
class Database {}
''',
      'a|lib/db.drift': '''
import 'entry.dart';

CREATE TABLE bars (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT
);
''',
    });

    final file =
        await state.driver.fullyAnalyze(Uri.parse('package:a/entry.dart'));

    expect(file.discovery, isA<DiscoveredDartLibrary>());
    expect(file.allErrors, isEmpty);

    final database = file.fileAnalysis!.resolvedDatabases.values.single;
    expect(database.availableElements.map((t) => t.id.name),
        containsAll(['foos', 'bars']));
  });

  group("reports error when an import can't be found", () {
    for (final extension in const ['drift', 'moor']) {
      test('in $extension files', () async {
        final backend = TestBackend.inTest({
          'a|lib/a.$extension': '''
import 'b.$extension';
''',
        });

        final result = await backend.analyze('package:a/a.$extension');

        expect(
            result.allErrors, [isDriftError(contains("can't be imported."))]);
      });
    }

    test('in a dart file', () async {
      final backend = TestBackend.inTest({
        'a|lib/a.dart': '''
import 'package:drift/drift.dart';

@DriftDatabase(include: {'b.drift'})
class Database {

}
''',
      });

      final result = await backend.analyze('package:a/a.dart');
      expect(
          result.allErrors, [isDriftError(contains('could not be imported'))]);
    });
  });

  test('resolves tables and queries', () async {
    final backend = TestBackend.inTest({
      'a|lib/database.dart': r'''
import 'package:drift/drift.dart';

import 'another.dart'; // so that the resolver picks it up

@DataClassName('UsesLanguage')
class UsedLanguages extends Table {
  IntColumn get language => integer()();
  IntColumn get library => integer()();

  @override
  Set<Column> get primaryKey => {language, library};
}

@DriftDatabase(
  tables: [UsedLanguages],
  include: {'package:a/tables.drift'},
  queries: {
    'transitiveImportTest': r'SELECT * FROM programming_languages ORDER BY $o',
  },
)
class Database {}
      ''',
      'a|lib/tables.drift': r'''
import 'another.dart';

CREATE TABLE reference_test (
  id INT NOT NULL PRIMARY KEY AUTOINCREMENT,
  library INT NOT NULL REFERENCES libraries(id)
);

CREATE TABLE libraries (
   id INT NOT NULL PRIMARY KEY AUTOINCREMENT,
   name TEXT NOT NULL
);

findLibraries: SELECT * FROM libraries WHERE name LIKE ?;
joinTest: SELECT * FROM reference_test r
  INNER JOIN libraries l ON l.id = r.library;
        ''',
      'a|lib/another.dart': r'''
import 'package:drift/drift.dart';

class ProgrammingLanguages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get popularity => integer().named('ieee_index').nullable()();
}
      ''',
    });

    final file = await backend.analyze('package:a/database.dart');
    expect(file.discovery, isA<DiscoveredDartLibrary>());
    expect(file.isFullyAnalyzed, isTrue);
    backend.expectNoErrors();

    final database = file.fileAnalysis!.resolvedDatabases.values.single;
    final availableTables = database.availableElements.whereType<DriftTable>();

    expect(
      availableTables.map((e) => e.schemaName),
      containsAll(['used_languages', 'libraries', 'programming_languages']),
    );

    final tableWithReferences =
        availableTables.singleWhere((e) => e.schemaName == 'reference_test');
    expect(tableWithReferences.references, [
      isA<DriftTable>().having((e) => e.schemaName, 'schemaName', 'libraries')
    ]);

    final importQuery = database.definedQueries.values.single;
    expect(importQuery.name, 'transitiveImportTest');
    expect(importQuery.resultSet?.matchingTable?.table.nameOfRowClass,
        'ProgrammingLanguage');
    expect(importQuery.declaredInDriftFile, isFalse);
    expect(
      importQuery.placeholders,
      contains(
        equals(
          FoundDartPlaceholder(
            SimpleDartPlaceholderType(SimpleDartPlaceholderKind.orderBy),
            'o',
            [
              AvailableDriftResultSet(
                'programming_languages',
                availableTables
                    .firstWhere((e) => e.schemaName == 'programming_languages'),
              )
            ],
          ),
        ),
      ),
    );

    final tablesFile = await backend.analyze('package:a/tables.drift');
    final librariesQuery = tablesFile.fileAnalysis!.resolvedQueries.values
        .singleWhere((e) => e.name == 'findLibraries') as SqlSelectQuery;
    expect(
        librariesQuery.variables.single.sqlType.builtin, DriftSqlType.string);
    expect(librariesQuery.declaredInDriftFile, isTrue);
  });

  test('still supports .moor files', () async {
    final state = TestBackend.inTest({
      'a|lib/main.dart': '''
import 'package:drift/drift.dart';

import 'table.dart';

@DriftDatabase(include: {'file.moor'})
class MyDatabase {}
''',
      'a|lib/file.moor': '''
CREATE TABLE users (
  id INTEGER NOT NULL PRIMARY KEY,
  name TEXT
);
''',
    });

    final file = await state.analyze('package:a/main.dart');
    state.expectNoErrors();

    final db = file.fileAnalysis!.resolvedDatabases.values.single;
    expect(db.availableElements, hasLength(1));
  });

  test('supports multiple references between same entities', () async {
    final state = TestBackend.inTest({
      'a|lib/a.dart': '''
import 'package:drift/drift.dart';

class OtherTable extends Table {
  TextColumn get id => text()();

  @override
  Set<Column> get primaryKey => {id};
}
class ThisTable extends Table {
  TextColumn get field1 => text().references(OtherTable, #id)();
  TextColumn get field2 => text().references(OtherTable, #id)();
  TextColumn get field3 => text().references(OtherTable, #id)();
}
''',
    });

    final file = await state.analyze('package:a/a.dart');
    state.expectNoErrors();

    final thisTable =
        file.analysis[file.id('this_table')]?.result as DriftTable;
    expect(
        thisTable.references, [file.analysis[file.id('other_table')]?.result]);
  });

  test('supports references across files', () async {
    final state = TestBackend.inTest({
      'a|lib/this_table.dart': '''
import 'package:drift/drift.dart';

import 'other_table.dart';

class ThisTable extends Table {
  TextColumn get id => text()();

  TextColumn get field1 => text().references(OtherTable, #id)();
  TextColumn get field2 => text().references(OtherTable, #id)();
  TextColumn get field3 => text().references(OtherTable, #id)();

  TextColumn get field4 => text()();

  @override
  Set<Column> get primaryKey => {id};
}
''',
      'a|lib/other_table.dart': '''
import 'package:drift/drift.dart';

class OtherTable extends Table {
  TextColumn get id => text()();

  TextColumn get field5 => text()();

  @override
  Set<Column> get primaryKey => {id};
}
''',
    });

    final file = await state.analyze('package:a/this_table.dart');
    state.expectNoErrors();

    final thisTable = file.analyzedElements.single;
    expect(thisTable.references, hasLength(1));
  });

  test('reports sensible error for missing table', () async {
    final state = TestBackend.inTest({
      'a|lib/a.drift': '''
getCompanyCustomersCount:
  SELECT COUNT(*) AS "count"
  FROM Customers AS c
  INNER JOIN Customer_Companies AS cc
    ON cc.customerId = c.id AND cc.companyId = :companyId;
''',
    });

    final file = await state.analyze('package:a/a.drift');
    final errors = file.analysis.values.single.errorsDuringAnalysis;
    expect(errors, [
      isDriftError(contains('`customers` could not be found in any import')),
      isDriftError(
          contains('`customer_companies` could not be found in any import')),
    ]);
  });
}
