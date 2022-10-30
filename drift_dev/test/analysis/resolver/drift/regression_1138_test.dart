import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  test('drift files can import original dart source', () async {
    final state = TestBackend.inTest({
      'a|lib/base.dart': r'''
import 'package:drift/drift.dart';

part 'base.g.dart';

class Events extends Table {
  IntColumn get id => integer().autoIncrement()();

  RealColumn get sumVal => real().withDefault(Constant(0))();
}

class Records extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get eventId => integer()();

  RealColumn get value => real().nullable()();
}

class Units extends Table {
  IntColumn get id => integer().autoIncrement()();
}

@DriftDatabase(include: {'customizedSQL.drift'})
class AppDatabase extends _$AppDatabase {
  AppDatabase()
      : super(FlutterQueryExecutor.inDatabaseFolder(
            path: "db.sqlite", logStatements: true));
}
      ''',
      'a|lib/customizedSQL.drift': '''
import 'base.dart';

create trigger addVal after insert on records when id = NEW.event_id BEGIN update events set sum_val = sum_val + NEW.value; END;
      ''',
    });

    final file = await state.analyze('package:a/base.dart');
    final db = file.fileAnalysis!.resolvedDatabases.values.single;

    expect(db.availableElements.whereType<DriftTable>(), hasLength(3));
  });
}
