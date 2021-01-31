import 'package:moor/moor.dart';

part 'database.g.dart';

@UseMoor(include: {'src/tables.moor'})
class MyDatabase extends _$MyDatabase {
  MyDatabase(DatabaseConnection conn) : super.connect(conn);

  @override
  int get schemaVersion => 1;
}
