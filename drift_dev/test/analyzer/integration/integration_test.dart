@Tags(['analyzer'])
import 'package:drift_dev/moor_generator.dart';
import 'package:drift_dev/src/analyzer/runner/file_graph.dart';
import 'package:drift_dev/src/analyzer/runner/results.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  late TestState state;

  setUpAll(() {
    state = TestState.withContent({
      'test_lib|lib/database.dart': r'''
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
  include: {'package:test_lib/tables.moor'},
  queries: {
    'transitiveImportTest': r'SELECT * FROM programming_languages ORDER BY $o',
  },
)
class Database {}
      ''',
      'test_lib|lib/tables.moor': r'''
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
      'test_lib|lib/another.dart': r'''
import 'package:drift/drift.dart';

class ProgrammingLanguages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get popularity => integer().named('ieee_index').nullable()();
}
      ''',
    });
  });

  tearDownAll(() {
    state.close();
  });

  setUp(() async {
    await state.runTask('package:test_lib/database.dart');
  });

  test('resolves tables and queries', () {
    final file = state.file('package:test_lib/database.dart');

    expect(file.state, FileState.analyzed);
    expect(file.errors.errors, isEmpty);

    final result = file.currentResult as ParsedDartFile;
    final database = result.declaredDatabases.single;

    expect(database.tables.map((t) => t.sqlName),
        containsAll(['used_languages', 'libraries', 'programming_languages']));

    final tableWithReferences =
        database.tables.singleWhere((r) => r.sqlName == 'reference_test');
    expect(tableWithReferences.references.single.sqlName, 'libraries');

    final importQuery = database.queries!
        .singleWhere((q) => q.name == 'transitiveImportTest') as SqlSelectQuery;
    expect(importQuery.resultSet.matchingTable!.table.dartTypeCode(),
        'ProgrammingLanguage');
    expect(importQuery.declaredInMoorFile, isFalse);
    expect(importQuery.hasMultipleTables, isFalse);
    expect(
      importQuery.placeholders,
      contains(
        equals(
          FoundDartPlaceholder(
            SimpleDartPlaceholderType(SimpleDartPlaceholderKind.orderBy),
            'o',
            [
              AvailableMoorResultSet(
                'programming_languages',
                database.tables
                    .firstWhere((e) => e.sqlName == 'programming_languages'),
              )
            ],
          ),
        ),
      ),
    );

    final librariesQuery = database.queries!
        .singleWhere((q) => q.name == 'findLibraries') as SqlSelectQuery;
    expect(librariesQuery.variables.single.type, DriftSqlType.string);
    expect(librariesQuery.declaredInMoorFile, isTrue);
  });
}
