import 'package:sally/sally.dart';

part 'tables.g.dart';

class Users extends Table {

  IntColumn get id => integer().autoIncrement()();
  TextColumn get userName => text().named('name').withLength(min: 6, max: 12)();
  TextColumn get bio => text()();

}

@UseSally(tables: [Users])
class ExampleDb extends _$ExampleDb {
  ExampleDb(QueryExecutor e) : super(e);
  @override
  MigrationStrategy get migration => MigrationStrategy();
  @override
  int get schemaVersion => 1;
}