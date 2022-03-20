import 'package:drift_core/drift_core.dart';
import 'package:drift_core/dialect/sqlite3.dart' as sql;

class Users extends SchemaTable {
  SchemaColumn<int> get id => column('id', sql.integer);
  SchemaColumn<String> get username => column('name', sql.text);

  @override
  List<SchemaColumn> get columns => [id, username];

  @override
  String get name => 'users';
}

void main() {
  final builder = QueryBuilder(sql.dialect);
  final users = Users();

  final query = builder.select([users.id.ref()])..from(users);
  final context = builder.newContext();
  query.writeInto(context);

  print(context.sql);
}
