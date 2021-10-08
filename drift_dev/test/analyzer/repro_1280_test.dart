// @dart=2.9
import 'package:drift_dev/src/analyzer/runner/results.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test('analyzes views referencing Dart tables', () async {
    final state = TestState.withContent({
      'a|lib/db.dart': '''
import 'package:drift/drift.dart';
import 'dart:io';

import 'entities/person.dart';

@DriftDatabase(tables: [Persons], include: {'query.moor'})
class MyDatabase {
  MyDatabase() : super(_openConnection());
  @override
  int get schemaVersion => 1;
}
      ''',
      'a|lib/query.moor': '''
import 'views.moor';

getPersonsWithFullNames: SELECT * FROM persons_with_full_name;
      ''',
      'a|lib/views.moor': '''
import 'entities/person.dart';

CREATE VIEW persons_with_full_name AS
SELECT id, name, last_name, '...' AS full_name
FROM persons;
      ''',
      'a|lib/entities/person.dart': '''
import 'package:drift/drift.dart';

class Persons extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get lastName => text()();
}
      ''',
    });
    addTearDown(state.close);

    final file = await state.analyze('package:a/db.dart');
    final result = file.currentResult as ParsedDartFile;

    final db = result.declaredDatabases.single;
    final view = db.views.single;
    expect(view.references, everyElement(isNotNull));
  });
}
