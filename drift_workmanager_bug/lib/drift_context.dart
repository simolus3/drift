import 'package:drift/drift.dart';
import 'package:drift_workmanager_bug/database.dart';

part 'drift_context.g.dart';

@DriftDatabase()
class DriftContext extends _$DriftContext {
  DriftContext(super.e);

  DriftContext.connect(DatabaseConnection connection)
      : super.connect(connection);

  @override
  int get schemaVersion => 1;

  static Future<void> test() async {
    final isolate = await ensureDriftIsolate();
    final connection = await isolate.connect();
    final database = DriftContext.connect(connection);

    await database.customSelect('SELECT 1').get();
    print('got row!');
    await database.close();
  }
}
