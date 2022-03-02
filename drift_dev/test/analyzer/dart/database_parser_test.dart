import 'package:drift_dev/src/analyzer/runner/results.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  test('parses schema version getter', () async {
    final state = TestState.withContent({
      'a|lib/main.dart': r'''
import 'package:drift/drift.dart';

@DriftDatabase()
class MyDatabase extends _$MyDatabase {
  @override
  int get schemaVersion => 13;
}
''',
    });
    addTearDown(state.close);

    final file = (await state.analyze('package:a/main.dart')).currentResult!;
    final db = (file as ParsedDartFile).declaredDatabases.single;

    expect(db.schemaVersion, 13);
  });

  test('parses schema version field', () async {
    final state = TestState.withContent({
      'a|lib/main.dart': r'''
import 'package:drift/drift.dart';

@DriftDatabase()
class MyDatabase extends _$MyDatabase {
  @override
  final int schemaVersion = 23;
}
''',
    });
    addTearDown(state.close);

    final file = (await state.analyze('package:a/main.dart')).currentResult!;
    final db = (file as ParsedDartFile).declaredDatabases.single;

    expect(db.schemaVersion, 23);
  });
}
