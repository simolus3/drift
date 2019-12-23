import 'package:moor/moor.dart';
import 'package:moor_ffi/moor_ffi.dart';

part 'database.g.dart';

class KeyValues extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@UseMoor(tables: [KeyValues])
class Database extends _$Database {
  Database() : super(VmDatabase.memory());

  @override
  int get schemaVersion => 1;
}
