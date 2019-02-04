part of 'example.dart';

class _$ShopDb extends GeneratedDatabase {

  _$ShopDb(SqlTypeSystem typeSystem, QueryExecutor executor) : super(typeSystem, executor);

  UsersTable get users => null;
}

class User {

  final int id;
  final String name;

  User(this.id, this.name);

}

class UsersTable extends Users implements TableInfo<Users, User> {

  final GeneratedDatabase db;

  UsersTable(this.db);

  @override
  List<Column> get $columns => [id, name];

  @override
  String get $tableName => "users";

  @override
  IntColumn get id => GeneratedIntColumn("id");

  @override
  TextColumn get name => GeneratedTextColumn("name");

  @override
  Users get asDslTable => this;

  @override
  User map(Map<String, dynamic> data) {
    final intType = db.typeSystem.forDartType<int>();
    final stringType = db.typeSystem.forDartType<String>();

    return User(intType.mapFromDatabaseResponse(data["id"]), stringType.mapFromDatabaseResponse(data["name"]));
  }

}
