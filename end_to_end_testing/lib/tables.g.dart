// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tables.dart';

// **************************************************************************
// SallyGenerator
// **************************************************************************

class User {
  final int id;
  final String userName;
  final String bio;
  User({this.id, this.userName, this.bio});
  @override
  int get hashCode =>
      ((id.hashCode) * 31 + userName.hashCode) * 31 + bio.hashCode;
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is User &&
          other.id == id &&
          other.userName == userName &&
          other.bio == bio);
}

class _$UsersTable extends Users implements TableInfo<Users, User> {
  final GeneratedDatabase _db;
  _$UsersTable(this._db);
  @override
  GeneratedIntColumn get id =>
      GeneratedIntColumn('id', false, hasAutoIncrement: true);
  @override
  GeneratedTextColumn get userName => GeneratedTextColumn(
        'name',
        false,
      );
  @override
  GeneratedTextColumn get bio => GeneratedTextColumn(
        'bio',
        false,
      );
  @override
  List<GeneratedColumn> get $columns => [id, userName, bio];
  @override
  Users get asDslTable => this;
  @override
  String get $tableName => 'users';
  @override
  void validateIntegrity(User instance, bool isInserting) =>
      id.isAcceptableValue(instance.id, isInserting) &&
      userName.isAcceptableValue(instance.userName, isInserting) &&
      bio.isAcceptableValue(instance.bio, isInserting);
  @override
  Set<GeneratedColumn> get $primaryKey => Set();
  @override
  User map(Map<String, dynamic> data) {
    final intType = _db.typeSystem.forDartType<int>();
    final stringType = _db.typeSystem.forDartType<String>();
    return User(
      id: intType.mapFromDatabaseResponse(data['id']),
      userName: stringType.mapFromDatabaseResponse(data['name']),
      bio: stringType.mapFromDatabaseResponse(data['bio']),
    );
  }

  @override
  Map<String, Variable> entityToSql(User d) {
    final map = <String, Variable>{};
    if (d.id != null) {
      map['id'] = Variable<int, IntType>(d.id);
    }
    if (d.userName != null) {
      map['name'] = Variable<String, StringType>(d.userName);
    }
    if (d.bio != null) {
      map['bio'] = Variable<String, StringType>(d.bio);
    }
    return map;
  }
}

abstract class _$ExampleDb extends GeneratedDatabase {
  _$ExampleDb(QueryExecutor e) : super(const SqlTypeSystem.withDefaults(), e);
  _$UsersTable get users => _$UsersTable(this);
  @override
  List<TableInfo> get allTables => [users];
}
