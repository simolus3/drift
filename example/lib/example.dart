import 'package:sally/sally.dart';
import 'package:sally/src/queries/table_structure.dart';

part 'example.g.dart';

class Products extends Table {

  IntColumn get id => integer().named("products_id").autoIncrement()();
  TextColumn get name => text()();

}

class Users extends Table {

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 6, max: 32)();

}

@UseData(tables: [Products, Users])
class ShopDb extends SallyDb with _$ShopDbMixin {

  Future<List<User>> allUsers() => users.select().get();
  Future<User> userByName(String name) => (users.select()..where((u) => u.name.equals(name))).single();

}