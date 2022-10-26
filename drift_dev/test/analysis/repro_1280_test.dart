import 'package:drift_dev/src/analysis/driver/state.dart';
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('analyzes views referencing Dart tables', () async {
    final state = TestBackend.inTest({
      'a|lib/db.dart': '''
import 'package:drift/drift.dart';
import 'dart:io';

import 'entities/person.dart';

@DriftDatabase(tables: [Persons], include: {'query.drift'})
class MyDatabase {
  MyDatabase() : super(_openConnection());
  @override
  int get schemaVersion => 1;
}
      ''',
      'a|lib/query.drift': '''
import 'views.drift';

getPersonsWithFullNames: SELECT * FROM persons_with_full_name;
      ''',
      'a|lib/views.drift': '''
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

    final file =
        await state.driver.fullyAnalyze(Uri.parse('package:a/db.dart'));

    expect(file.discovery, isA<DiscoveredDartLibrary>());
    state.expectNoErrors();

    final db = file.fileAnalysis!.resolvedDatabases.values.single;
    final view = db.availableElements.whereType<DriftView>().single;
    expect(view.references, everyElement(isNotNull));
  });
}
