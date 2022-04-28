import 'package:drift_core/dialect/common.dart' as sql;
import 'package:drift_core/dialect/sqlite3.dart' as sqlite3;
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
  sql.runWithDialect(
      dialect: sqlite3.dialect,
      body: () {
        final builder = QueryBuilder(sql.dialect);
        final users = Users();
        final groups = Groups();

        print(builder.build((builder) => builder.createTable(users)).sql);

        final context =
            builder.build((builder) => builder.select([users.star()])
              ..from(users)
              ..where(users.id().eq(sqlVar(3)))
              ..innerJoin(groups, on: groups.admin().eq(users.id()))
              ..limit(10));

        print(context.sql);
        print(context.boundVariables);

        print(
          builder.build((builder) => builder.delete(from: users)).sql,
        );
      });
}
