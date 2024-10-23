import 'package:drift/drift.dart';

part 'database.g.dart';

@DriftDatabase(include: {'tables.drift'})
class MyDatabase extends _$MyDatabase {
  MyDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}
