// @dart=2.9
import 'package:drift_dev/src/analyzer/runner/results.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  test('moor files can import original dart source', () async {
    final state = TestState.withContent({
      'a|lib/base.dart': r'''
import 'package:moor/moor.dart';

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

@UseMoor(include: {'customizedSQL.moor'})
class AppDatabase extends _$AppDatabase {
  AppDatabase()
      : super(FlutterQueryExecutor.inDatabaseFolder(
            path: "db.sqlite", logStatements: true));
}
      ''',
      'a|lib/customizedSQL.moor': '''
import 'base.dart';

create trigger addVal after insert on records when id = NEW.event_id BEGIN update events set sum_val = sum_val + NEW.value; END;
      ''',
    });
    addTearDown(state.close);

    final file = await state.analyze('package:a/base.dart');
    final result = file.currentResult as ParsedDartFile;
    final db = result.declaredDatabases.single;

    expect(db.tables, hasLength(3));
  });
}
