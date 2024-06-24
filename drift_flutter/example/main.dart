import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'main.g.dart';

void main() async {
  final database = ExampleDatabase();
  await database.exampleTable.all().get();
}

class ExampleTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get description => text()();
}

@DriftDatabase(tables: [ExampleTable])
final class ExampleDatabase extends _$ExampleDatabase {
  ExampleDatabase([QueryExecutor? implementation])
      : super(implementation ?? driftDatabase(name: 'db'));

  @override
  int get schemaVersion => 1;
}
