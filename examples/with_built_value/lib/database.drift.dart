// ignore_for_file: type=lint, invalid_use_of_internal_member
import 'package:drift/drift.dart' as i0;
import 'package:with_built_value/tables.drift.dart' as i1;

abstract class $Database extends i0.GeneratedDatabase {
  $Database(i0.QueryExecutor e) : super(e);
  $DatabaseManager get managers => $DatabaseManager(this);
  late final i1.Users users = i1.Users(this);
  @override
  Iterable<i0.TableInfo<i0.Table, Object?>> get allTables =>
      allSchemaEntities.whereType<i0.TableInfo<i0.Table, Object?>>();
  @override
  List<i0.DatabaseSchemaEntity> get allSchemaEntities => [users];
}

class $DatabaseManager {
  final $Database _db;
  $DatabaseManager(this._db);
  i1.$UsersTableManager get users => i1.$UsersTableManager(_db, _db.users);
}
