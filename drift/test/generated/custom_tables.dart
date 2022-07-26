import 'package:drift/drift.dart';

import 'converter.dart';
import 'data_classes.dart';

export 'data_classes.dart';

part 'custom_tables.g.dart';

@DriftDatabase(
  include: {'tables.drift'},
  queries: {
    'writeConfig': 'REPLACE INTO config (config_key, config_value) '
        'VALUES (:key, :value)'
  },
)
class CustomTablesDb extends _$CustomTablesDb {
  CustomTablesDb(QueryExecutor e) : super(e) {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  }

  CustomTablesDb.connect(DatabaseConnection connection)
      : super.connect(connection) {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy migration = MigrationStrategy();

  @override
  DriftDatabaseOptions options =
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}
