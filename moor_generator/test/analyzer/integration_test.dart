import 'package:build/build.dart';
import 'package:moor_generator/src/analyzer/runner/file_graph.dart';
import 'package:moor_generator/src/analyzer/runner/results.dart';
import 'package:moor_generator/src/analyzer/runner/task.dart';
import 'package:moor_generator/src/analyzer/session.dart';
import 'package:moor_generator/src/model/specified_column.dart';
import 'package:moor_generator/src/model/sql_query.dart';
import 'package:test/test.dart';

import '../utils/test_backend.dart';

void main() {
  TestBackend backend;
  MoorSession session;

  setUpAll(() {
    backend = TestBackend(
      {
        AssetId.parse('test_lib|lib/database.dart'): r'''
import 'package:moor/moor.dart';

import 'another.dart'; // so that the resolver picks it up

@DataClassName('UsesLanguage')
class UsedLanguages extends Table {
  IntColumn get language => integer()();
  IntColumn get library => integer()();
  
  @override
  Set<Column> get primaryKey => {language, library};
}

@UseMoor(
  tables: [UsedLanguages],
  include: {'package:test_lib/tables.moor'},
  queries: {
    'transitiveImportTest': 'SELECT * FROM programming_languages',
  },
)
class Database {}

      ''',
        AssetId.parse('test_lib|lib/tables.moor'): r'''
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
        ''',
        AssetId.parse('test_lib|lib/another.dart'): r'''
import 'package:moor/moor.dart';
      
class ProgrammingLanguages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get popularity => integer().named('ieee_index').nullable()();
}
      ''',
      },
    );
    session = backend.session;
  });

  tearDownAll(() {
    backend.finish();
  });

  Task task;

  setUp(() async {
    final backendTask =
        backend.startTask(Uri.parse('package:test_lib/database.dart'));
    task = session.startTask(backendTask);
    await task.runTask();
  });

  test('resolves tables and queries', () {
    final file =
        session.registerFile(Uri.parse('package:test_lib/database.dart'));

    expect(file.state, FileState.analyzed);
    expect(file.errors.errors, isEmpty);

    final result = file.currentResult as ParsedDartFile;
    final database = result.declaredDatabases.single;

    expect(database.allTables.map((t) => t.sqlName),
        containsAll(['used_languages', 'libraries', 'programming_languages']));

    final tableWithReferences =
        database.allTables.singleWhere((r) => r.sqlName == 'reference_test');
    expect(tableWithReferences.references.single.sqlName, 'libraries');

    final importQuery = database.resolvedQueries
        .singleWhere((q) => q.name == 'transitiveImportTest') as SqlSelectQuery;
    expect(importQuery.resultClassName, 'ProgrammingLanguage');
    expect(importQuery.declaredInMoorFile, isFalse);

    final librariesQuery = database.resolvedQueries
        .singleWhere((q) => q.name == 'findLibraries') as SqlSelectQuery;
    expect(librariesQuery.variables.single.type, ColumnType.text);
    expect(librariesQuery.declaredInMoorFile, isTrue);
  });
}
