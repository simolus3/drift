import 'package:sally/src/runtime/structure/columns.dart';
import 'package:sally/src/runtime/structure/table_info.dart';

typedef Future<void> OnCreate(Migrator m);
typedef Future<void> OnUpgrade(Migrator m, int from, int to);

Future<void> _defaultOnCreate(Migrator m) => m.createAllTables();
Future<void> _defaultOnUpdate(Migrator m, int from, int to) async =>
    throw Exception("You've bumped the schema version for your sally database "
    "but didn't provide a strategy for schema updates. Please do that by "
    'adapting the migrations getter in your database class.');

class MigrationStrategy {
  final OnCreate onCreate;
  final OnUpgrade onUpgrade;

  MigrationStrategy({
    this.onCreate = _defaultOnCreate,
    this.onUpgrade = _defaultOnUpdate,
  });
}

class Migrator {
  Future<void> createAllTables() async {}

  Future<void> createTable(TableInfo table) async {}

  Future<void> deleteTable(String name) async {}

  Future<void> addColumn(TableInfo table, GeneratedColumn column) async {}

  Future<void> deleteColumn(TableInfo table, String columnName) async {}

  Future<void> issueCustomQuery(String sql) async {}
}
