import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('gracefully handles daos with invalid types', () async {
    final state = TestBackend.inTest({
      'a|lib/bar.dart': '''
import 'package:drift/drift.dart';

class Foos extends Table {
  IntColumn get id => integer().autoIncrement()();
}

@DriftDatabase() class Db {}

@DriftAccessor(tables: [Foos, Db])
class Dao extends DatabaseAccessor<Db> {}
      ''',
    });

    final file =
        await state.driver.fullyAnalyze(Uri.parse('package:a/bar.dart'));

    expect(file.allErrors, isNotEmpty);

    final dao = file.analyzedElements.whereType<DatabaseAccessor>().single;
    expect(dao.declaredTables, hasLength(1));
  });
}
