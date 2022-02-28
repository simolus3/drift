import 'package:drift_dev/src/analyzer/runner/results.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  test("tables imported in two ways aren't duplicated", () async {
    final state = TestState.withContent({
      'foo|lib/main.dart': '''
import 'package:drift/drift.dart';

import 'table.dart';

@DriftDatabase(tables: [Users], include: {'file.moor'})
class MyDatabase {}
      ''',
      'foo|lib/file.moor': '''
import 'table.dart';
      ''',
      'foo|lib/table.dart': '''
import 'package:drift/drift.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
}
      '''
    });

    final dbFile = await state.analyze('package:foo/main.dart');
    final db =
        (dbFile.currentResult as ParsedDartFile).declaredDatabases.single;

    state.close();
    expect(db.entities, hasLength(1));
  });
}
