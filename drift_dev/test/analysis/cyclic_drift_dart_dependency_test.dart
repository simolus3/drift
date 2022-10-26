@Tags(['analyzer'])
import 'package:drift_dev/src/analysis/driver/state.dart';
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
}
