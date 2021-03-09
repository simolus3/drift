// GENERATED CODE, DO NOT EDIT BY HAND.
//@dart=2.12
import 'package:moor/moor.dart';

class _Users extends Table with TableInfo {
  final GeneratedDatabase _db;
  final String? _alias;
  _Users(this._db, [this._alias]);
  late final GeneratedIntColumn id = _constructId();
  GeneratedIntColumn _constructId() {
    return GeneratedIntColumn('id', $tableName, false,
        hasAutoIncrement: true, declaredAsPrimaryKey: true);
  }

  late final GeneratedTextColumn name = _constructName();
  GeneratedTextColumn _constructName() {
    return GeneratedTextColumn(
      'name',
      $tableName,
      false,
    );
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
  Never map(Map<String, dynamic> data, {String? tablePrefix}) {
    throw UnsupportedError('TableInfo.map in schema verification code');
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
  final String? _alias;
  _Groups(this._db, [this._alias]);
  late final GeneratedIntColumn id = _constructId();
  GeneratedIntColumn _constructId() {
    return GeneratedIntColumn('id', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  late final GeneratedTextColumn title = _constructTitle();
  GeneratedTextColumn _constructTitle() {
    return GeneratedTextColumn('title', $tableName, false,
        $customConstraints: 'NOT NULL');
  }

  late final GeneratedBoolColumn deleted = _constructDeleted();
  GeneratedBoolColumn _constructDeleted() {
    return GeneratedBoolColumn('deleted', $tableName, true,
        $customConstraints: 'DEFAULT FALSE',
        defaultValue: const CustomExpression<bool>('FALSE'));
  }

  late final GeneratedIntColumn owner = _constructOwner();
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
  Never map(Map<String, dynamic> data, {String? tablePrefix}) {
    throw UnsupportedError('TableInfo.map in schema verification code');
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

class DatabaseAtV3 extends GeneratedDatabase {
  DatabaseAtV3(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e);
  DatabaseAtV3.connect(DatabaseConnection c) : super.connect(c);
  late final _Users users = _Users(this);
  late final _Groups groups = _Groups(this);
  @override
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [users, groups];
  @override
  int get schemaVersion => 3;
}
