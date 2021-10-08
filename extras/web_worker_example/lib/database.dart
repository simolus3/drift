import 'package:drift/drift.dart';

part 'database.g.dart';

@DriftDatabase(include: {'src/tables.drift'})
class MyDatabase extends _$MyDatabase {
  MyDatabase(DatabaseConnection conn) : super.connect(conn);

  @override
  int get schemaVersion => 1;
}
