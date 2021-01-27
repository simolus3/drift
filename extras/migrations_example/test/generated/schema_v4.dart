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

  GeneratedTextColumn _name;
  GeneratedTextColumn get name => _name ??= _constructName();
  GeneratedTextColumn _constructName() {
    return GeneratedTextColumn('name', $tableName, false,
        defaultValue: const Constant('name'));
  }

  @override
  List<GeneratedColumn> get $columns => [id, name];
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

  @override
  bool get dontWriteConstraints => false;
}

class _Groups extends Table with TableInfo {
  final GeneratedDatabase _db;
  final String _alias;
  _Groups(this._db, [this._alias]);
  GeneratedIntColumn _id;
  GeneratedIntColumn get id => _id ??= _constructId();
  GeneratedIntColumn _constructId() {
    return GeneratedIntColumn('id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  GeneratedTextColumn _title;
  GeneratedTextColumn get title => _title ??= _constructTitle();
  GeneratedTextColumn _constructTitle() {
    return GeneratedTextColumn('title', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  GeneratedBoolColumn _deleted;
  GeneratedBoolColumn get deleted => _deleted ??= _constructDeleted();
  GeneratedBoolColumn _constructDeleted() {
    return GeneratedBoolColumn('deleted', $tableName, true,
        $customConstraints: 'DEFAULT FALSE',
        defaultValue: const CustomExpression<bool>('FALSE'));
  }

  GeneratedIntColumn _owner;
  GeneratedIntColumn get owner => _owner ??= _constructOwner();
  GeneratedIntColumn _constructOwner() {
    return GeneratedIntColumn('owner', $tableName, false,
        $customConstraints: 'NOT NULL REFERENCES users (id)');
  }

  @override
  List<GeneratedColumn> get $columns => [id, title, deleted, owner];
  @override
  _Groups get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'groups';
  @override
  final String actualTableName = 'groups';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Null map(Map<String, dynamic> data, {String tablePrefix}) {
    return null;
  }

  @override
  _Groups createAlias(String alias) {
    return _Groups(_db, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY (id)'];
  @override
  bool get dontWriteConstraints => true;
}

class DatabaseAtV4 extends GeneratedDatabase {
  DatabaseAtV4(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e);
  DatabaseAtV4.connect(DatabaseConnection c) : super.connect(c);
  _Users _users;
  _Users get users => _users ??= _Users(this);
  _Groups _groups;
  _Groups get groups => _groups ??= _Groups(this);
  @override
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [users, groups];
  @override
  int get schemaVersion => 4;
}
