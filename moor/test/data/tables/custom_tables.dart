import 'package:moor/moor.dart';

import 'converter.dart';
import 'data_classes.dart';

export 'data_classes.dart';

part 'custom_tables.g.dart';

@UseMoor(
  include: {'tables.moor'},
  queries: {
    'writeConfig': 'REPLACE INTO config (config_key, config_value) '
        'VALUES (:key, :value)'
  },
)
class CustomTablesDb extends _$CustomTablesDb {
  CustomTablesDb(QueryExecutor e) : super(e) {
    moorRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy migration = MigrationStrategy();
}
