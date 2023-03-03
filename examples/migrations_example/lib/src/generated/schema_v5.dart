// GENERATED CODE, DO NOT EDIT BY HAND.
// ignore_for_file: type=lint
//@dart=2.12
import 'package:drift/drift.dart';

class Users extends Table with TableInfo {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Users(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('name'));
  late final GeneratedColumn<int> nextUser = GeneratedColumn<int>(
      'next_user', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  @override
  List<GeneratedColumn> get $columns => [id, name, nextUser];
  @override
  String get aliasedName => _alias ?? 'users';
  @override
  String get actualTableName => 'users';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Never map(Map<String, dynamic> data, {String? tablePrefix}) {
    throw UnsupportedError('TableInfo.map in schema verification code');
  }

  @override
  Users createAlias(String alias) {
    return Users(attachedDatabase, alias);
  }
}

class Groups extends Table with TableInfo {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Groups(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
      'deleted', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      $customConstraints: 'DEFAULT FALSE',
      defaultValue: const CustomExpression<bool>('FALSE'));
  late final GeneratedColumn<int> owner = GeneratedColumn<int>(
      'owner', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL REFERENCES users (id)');
  @override
  List<GeneratedColumn> get $columns => [id, title, deleted, owner];
  @override
  String get aliasedName => _alias ?? 'groups';
  @override
  String get actualTableName => 'groups';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Never map(Map<String, dynamic> data, {String? tablePrefix}) {
    throw UnsupportedError('TableInfo.map in schema verification code');
  }

  @override
  Groups createAlias(String alias) {
    return Groups(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY (id)'];
  @override
  bool get dontWriteConstraints => true;
}

class GroupCount extends ViewInfo<GroupCount, Never> implements HasResultSet {
  final String? _alias;
  @override
  final DatabaseAtV5 attachedDatabase;
  GroupCount(this.attachedDatabase, [this._alias]);
  @override
  List<GeneratedColumn> get $columns => [id, name, nextUser, groupCount];
  @override
  String get aliasedName => _alias ?? entityName;
  @override
  String get entityName => 'group_count';
  @override
  String get createViewStmt =>
      'CREATE VIEW group_count AS SELECT users.*, (SELECT COUNT(*) FROM "groups" WHERE owner = users.id) AS group_count FROM users';
  @override
  GroupCount get asDslTable => this;
  @override
  Never map(Map<String, dynamic> data, {String? tablePrefix}) {
    throw UnsupportedError('TableInfo.map in schema verification code');
  }

  late final GeneratedColumn<int> id =
      GeneratedColumn<int>('id', aliasedName, false, type: DriftSqlType.int);
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string);
  late final GeneratedColumn<int> nextUser = GeneratedColumn<int>(
      'next_user', aliasedName, true,
      type: DriftSqlType.int);
  late final GeneratedColumn<int> groupCount = GeneratedColumn<int>(
      'group_count', aliasedName, false,
      type: DriftSqlType.int);
  @override
  GroupCount createAlias(String alias) {
    return GroupCount(attachedDatabase, alias);
  }

  @override
  Query? get query => null;
  @override
  Set<String> get readTables => const {};
}

class DatabaseAtV5 extends GeneratedDatabase {
  DatabaseAtV5(QueryExecutor e) : super(e);
  late final Users users = Users(this);
  late final Groups groups = Groups(this);
  late final GroupCount groupCount = GroupCount(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [users, groups, groupCount];
  @override
  int get schemaVersion => 5;
}
