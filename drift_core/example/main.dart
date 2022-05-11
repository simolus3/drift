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

        final customExpr = users.id() + sqlVar(3);
        final select = builder.select([users.star(), customExpr])
          ..from(users)
          ..where(users.id().eq(sqlVar(3)))
          ..innerJoin(groups, on: groups.admin().eq(users.id()))
          ..limit(10);
        final context = builder.newContext();
        final mapping = select.writeInto(context);

        print(context.sql);
        print(context.boundVariables);
        print(mapping.columnNameInTable(users.id));
        print(mapping.columnName(customExpr));

        print(
          builder.build((builder) => builder.delete(from: users)).sql,
        );
      });
}
