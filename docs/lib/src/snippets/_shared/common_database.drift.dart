// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:drift_website/src/snippets/_shared/todo_tables.drift.dart'
    as i1;

abstract class $MyDatabase extends i0.GeneratedDatabase {
  $MyDatabase(i0.QueryExecutor e) : super(e);
  $MyDatabaseManager get managers => $MyDatabaseManager(this);
  late final i1.$CategoriesTable categories = i1.$CategoriesTable(this);
  late final i1.$TodoItemsTable todoItems = i1.$TodoItemsTable(this);
  @override
  Iterable<i0.TableInfo<i0.Table, Object?>> get allTables =>
      allSchemaEntities.whereType<i0.TableInfo<i0.Table, Object?>>();
  @override
  List<i0.DatabaseSchemaEntity> get allSchemaEntities => [
    categories,
    todoItems,
  ];
}

class $MyDatabaseManager {
  final $MyDatabase _db;
  $MyDatabaseManager(this._db);
  i1.$$CategoriesTableTableManager get categories =>
      i1.$$CategoriesTableTableManager(_db, _db.categories);
  i1.$$TodoItemsTableTableManager get todoItems =>
      i1.$$TodoItemsTableTableManager(_db, _db.todoItems);
}
