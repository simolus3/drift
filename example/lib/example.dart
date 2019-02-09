import 'package:sally/sally.dart';

part 'example.g.dart';

class Products extends Table {
  IntColumn get id => integer().named('products_id').autoIncrement()();
  TextColumn get name => text()();
}

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 6, max: 32)();
}

@UseSally(tables: [Products, Users])
class ShopDb extends _$ShopDb {
  Future<List<User>> allUsers() => select(users).get();
  Future<List<User>> userByName(String name) =>
      (select(users)..where((u) => u.name.equalsVal(name))).get();

  Future<void> deleteUser(User user) =>
      (delete(users)..where((u) => u.id.equalsVal(user.id))).go();

  @override
  MigrationStrategy get migration => MigrationStrategy();
  @override
  int get schemaVersion => 1;
}
