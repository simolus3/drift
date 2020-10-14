// GENERATED CODE, DO NOT EDIT BY HAND.
import 'package:moor/moor.dart';

class _Users extends Table with TableInfo {
  final GeneratedDatabase _db;
  final String _alias;
  _Users(this._db, [this._alias]);
  GeneratedIntColumn _id;
  GeneratedIntColumn get id => _id ??= _constructId();
  GeneratedIntColumn _constructId() {
    return GeneratedIntColumn('id', $tableName, false,
        hasAutoIncrement: true, declaredAsPrimaryKey: true);
  }

  @override
  List<GeneratedColumn> get $columns => [id];
  @override
  _Users get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'users';
  @override
  final String actualTableName = 'users';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Null map(Map<String, dynamic> data, {String tablePrefix}) {
    return null;
  }

  @override
  _Users createAlias(String alias) {
    return _Users(_db, alias);
  }
}

class DatabaseAtV1 extends GeneratedDatabase {
  DatabaseAtV1(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e);
  DatabaseAtV1.connect(DatabaseConnection c) : super.connect(c);
  _Users _users;
  _Users get users => _users ??= _Users(this);
  @override
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [users];
  @override
  int get schemaVersion => 1;
}
