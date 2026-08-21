import 'package:drift3_preview/drift.dart';
import 'package:drift3_flutter_preview/drift_flutter.dart';

part 'main.g.dart';

void main() async {
  final database = ExampleDatabase();
  await database.select(database.exampleTable).get();
}

class ExampleTable extends Table {
  IntColumn get id => integer().autoIncrement();
  TextColumn get description => text();
}

@DriftDatabase(tables: [ExampleTable])
final class ExampleDatabase extends _$ExampleDatabase {
  ExampleDatabase([DriftConnection? implementation])
    : super(implementation ?? driftDatabase(name: 'db'));

  @override
  int get schemaVersion => 1;
}
