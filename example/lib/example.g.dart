part of 'example.dart';

class _$ShopDbMixin implements QueryExecutor {

  final StructuredUsersTable users = StructuredUsersTable();

  Future<List<Map<String, dynamic>>> executeQuery(String sql, [dynamic params]) {
    return null;
  }

  Future<int> executeDelete(String sql, [dynamic params]) {
    return null;
  }

}

class StructuredUsersTable extends Users with TableStructure<Users, User> {


  @override
  final StructuredIntColumn id = StructuredIntColumn("id");
  @override
  final StructuredTextColumn name = StructuredTextColumn("name");

  @override
  String get sqlTableName => "users";

  @override
  User parse(Map<String, dynamic> result) {
    return User(result["id"], result["name"]);
  }
  @override
  Users get asTable => this;

}

class User {

  final int id;
  final String name;

  User(this.id, this.name);

}