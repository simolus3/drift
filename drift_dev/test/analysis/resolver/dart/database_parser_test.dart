import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  final mainUri = Uri.parse('package:a/main.dart');

  test('parses schema version getter', () async {
    final backend = TestBackend.inTest({
      'a|lib/main.dart': r'''
import 'package:drift/drift.dart';

@DriftDatabase()
class MyDatabase extends _$MyDatabase {
  @override
  int get schemaVersion => 13;
}
''',
    });

    final fileState = await backend.driver.fullyAnalyze(mainUri);
    backend.expectNoErrors();

    final db = fileState.analyzedElements.single as DriftDatabase;
    expect(db.schemaVersion, 13);
  });

  test('parses schema version field', () async {
    final backend = TestBackend.inTest({
      'a|lib/main.dart': r'''
import 'package:drift/drift.dart';

@DriftDatabase()
class MyDatabase extends _$MyDatabase {
  @override
  final int schemaVersion = 23;
}
''',
    });

    final fileState = await backend.driver.fullyAnalyze(mainUri);
    backend.expectNoErrors();

    final db = fileState.analyzedElements.single as DriftDatabase;
    expect(db.schemaVersion, 23);
  });

  test('does not warn about missing tables parameter', () async {
    final backend = TestBackend.inTest({
      'a|lib/main.dart': r'''
import 'package:drift/drift.dart';

@DriftDatabase(include: {'foo.drift'})
class MyDatabase extends _$MyDatabase {

}

@DriftDatabase(include: {'foo.drift'}, tables: [])
class MyDatabase2 extends _$MyDatabase {

}
''',
    });

    await backend.driver.fullyAnalyze(mainUri);
    backend.expectNoErrors();
  });
}
