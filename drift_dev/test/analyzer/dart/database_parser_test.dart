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

    final fileState = await state.analyze('package:a/main.dart');
    expect(fileState.errors.errors, isEmpty);

    final file = fileState.currentResult!;
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

    final fileState = await state.analyze('package:a/main.dart');
    expect(fileState.errors.errors, isEmpty);

    final file = fileState.currentResult!;
    final db = (file as ParsedDartFile).declaredDatabases.single;

    expect(db.schemaVersion, 23);
  });

  test('does not warn about missing tables parameter', () async {
    final state = TestState.withContent({
      'a|lib/main.dart': r'''
import 'package:drift/drift.dart';

@DriftDatabase(include: {'foo.drift'})
class MyDatabase extends _$MyDatabase {

}

@DriftDatabase(include: {'foo.drift'}, tables: [])
class MyDatabase2 extends _$MyDatabase {

}
''',
      'a|lib/foo.drift': '',
    });
    addTearDown(state.close);

    final fileState = await state.analyze('package:a/main.dart');
    expect(fileState.errors.errors, isEmpty);
  });
}
