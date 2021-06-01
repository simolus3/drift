// GENERATED CODE, DO NOT EDIT BY HAND.
//@dart=2.12
import 'package:moor/moor.dart';

class UsersData extends DataClass implements Insertable<UsersData> {
  final int id;
  final String name;
  UsersData({required this.id, required this.name});
  factory UsersData.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return UsersData(
      id: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
      name: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}name'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      name: Value(name),
    );
  }

  factory UsersData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return UsersData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  UsersData copyWith({int? id, String? name}) => UsersData(
        id: id ?? this.id,
        name: name ?? this.name,
      );
  @override
  String toString() {
    return (StringBuffer('UsersData(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(id.hashCode, name.hashCode));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UsersData && other.id == this.id && other.name == this.name);
}

class UsersCompanion extends UpdateCompanion<UsersData> {
  final Value<int> id;
  final Value<String> name;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
  }) : name = Value(name);
  static Insertable<UsersData> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  UsersCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return UsersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class Users extends Table with TableInfo {
  final GeneratedDatabase _db;
  final String? _alias;
  Users(this._db, [this._alias]);
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
  Users get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'users';
  @override
  final String actualTableName = 'users';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UsersData map(Map<String, dynamic> data, {String? tablePrefix}) {
    return UsersData.fromData(data, _db,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  Users createAlias(String alias) {
    return Users(_db, alias);
  }

  @override
  bool get dontWriteConstraints => false;
}

class GroupsData extends DataClass implements Insertable<GroupsData> {
  final int id;
  final String title;
  final bool? deleted;
  final int owner;
  GroupsData(
      {required this.id,
      required this.title,
      this.deleted,
      required this.owner});
  factory GroupsData.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return GroupsData(
      id: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
      title: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}title'])!,
      deleted: const BoolType()
          .mapFromDatabaseResponse(data['${effectivePrefix}deleted']),
      owner: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}owner'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || deleted != null) {
      map['deleted'] = Variable<bool?>(deleted);
    }
    map['owner'] = Variable<int>(owner);
    return map;
  }

  GroupsCompanion toCompanion(bool nullToAbsent) {
    return GroupsCompanion(
      id: Value(id),
      title: Value(title),
      deleted: deleted == null && nullToAbsent
          ? const Value.absent()
          : Value(deleted),
      owner: Value(owner),
    );
  }

  factory GroupsData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return GroupsData(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      deleted: serializer.fromJson<bool?>(json['deleted']),
      owner: serializer.fromJson<int>(json['owner']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'deleted': serializer.toJson<bool?>(deleted),
      'owner': serializer.toJson<int>(owner),
    };
  }

  GroupsData copyWith({int? id, String? title, bool? deleted, int? owner}) =>
      GroupsData(
        id: id ?? this.id,
        title: title ?? this.title,
        deleted: deleted ?? this.deleted,
        owner: owner ?? this.owner,
      );
  @override
  String toString() {
    return (StringBuffer('GroupsData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('deleted: $deleted, ')
          ..write('owner: $owner')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(id.hashCode,
      $mrjc(title.hashCode, $mrjc(deleted.hashCode, owner.hashCode))));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupsData &&
          other.id == this.id &&
          other.title == this.title &&
          other.deleted == this.deleted &&
          other.owner == this.owner);
}

class GroupsCompanion extends UpdateCompanion<GroupsData> {
  final Value<int> id;
  final Value<String> title;
  final Value<bool?> deleted;
  final Value<int> owner;
  const GroupsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.deleted = const Value.absent(),
    this.owner = const Value.absent(),
  });
  GroupsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.deleted = const Value.absent(),
    required int owner,
  })  : title = Value(title),
        owner = Value(owner);
  static Insertable<GroupsData> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<bool?>? deleted,
    Expression<int>? owner,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (deleted != null) 'deleted': deleted,
      if (owner != null) 'owner': owner,
    });
  }

  GroupsCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<bool?>? deleted,
      Value<int>? owner}) {
    return GroupsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      deleted: deleted ?? this.deleted,
      owner: owner ?? this.owner,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool?>(deleted.value);
    }
    if (owner.present) {
      map['owner'] = Variable<int>(owner.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('deleted: $deleted, ')
          ..write('owner: $owner')
          ..write(')'))
        .toString();
  }
}

class Groups extends Table with TableInfo {
  final GeneratedDatabase _db;
  final String? _alias;
  Groups(this._db, [this._alias]);
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
  Groups get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'groups';
  @override
  final String actualTableName = 'groups';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GroupsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    return GroupsData.fromData(data, _db,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  Groups createAlias(String alias) {
    return Groups(_db, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY (id)'];
  @override
  bool get dontWriteConstraints => true;
}

class DatabaseAtV3 extends GeneratedDatabase {
  DatabaseAtV3(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e);
  DatabaseAtV3.connect(DatabaseConnection c) : super.connect(c);
  late final Users users = Users(this);
  late final Groups groups = Groups(this);
  @override
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [users, groups];
  @override
  int get schemaVersion => 3;
}
