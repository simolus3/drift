import 'package:moor/moor_web.dart';

class TestDb extends GeneratedDatabase {
  TestDb(QueryExecutor executor)
      : super(const SqlTypeSystem.withDefaults(), executor);

  @override
  List<TableInfo<Table, DataClass>> get allTables => const [];

  @override
  int get schemaVersion => 1;
}

void main() async {
  final executor = AlaSqlDatabase('database');
  executor.databaseInfo = TestDb(executor);

  final result = await executor.doWhenOpened((e) {
    return e.runSelect('SELECT 1', const []);
  });
  print(result);
}
