//@dart=2.9
import 'package:drift_dev/src/analyzer/runner/results.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test('gracefully handles daos with invalid types', () async {
    final state = TestState.withContent({
      'foo|lib/bar.dart': '''
import 'package:drift/drift.dart';

class Foos extends Table {
  IntColumn get id => integer().autoIncrement()();
}

@DriftDatabase() class Db {}

@DriftAccessor(tables: [Foos, Db])
class Dao extends DatabaseAccessor<Db> {}
      ''',
    });

    final file = await state.analyze('package:foo/bar.dart');
    final content = file.currentResult as ParsedDartFile;
    final dao = content.declaredDaos.single;

    expect(file.errors.errors, isNotEmpty);
    expect(dao.declaredTables, hasLength(1));
  });
}
