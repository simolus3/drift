import 'package:drift_core/dialect/sqlite3.dart' as sql;
import 'package:drift_core/drift_core.dart';

class Users extends SchemaTable {
  SchemaColumn<int> get id => column('id', sql.integer);
  SchemaColumn<String> get username => column('name', sql.text);

  @override
  List<SchemaColumn> get columns => [id, username];

  @override
  String get tableName => 'users';
}

class Groups extends SchemaTable {
  SchemaColumn<int> get admin => column('admin', sql.integer);
  SchemaColumn<String> get description => column('description', sql.text);

  @override
  List<SchemaColumn> get columns => [admin];
  @override
  String get tableName => 'groups';
}

void main() {
  final builder = QueryBuilder(sql.dialect);
  final users = Users();
  final groups = Groups();

  print(
    builder
        .build((builder) => builder.select([users.id()])
          ..from(users)
          ..innerJoin(groups, on: groups.admin().eq(users.id())))
        .sql,
  );

  print(
    builder.build((builder) => builder.delete(from: users)).sql,
  );
}
