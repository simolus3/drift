// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:drift_docs/snippets/_shared/todo_tables.drift.dart' as i1;
import 'package:drift/internal/modular.dart' as i2;

abstract class $MyDatabase extends i0.GeneratedDatabase {
  $MyDatabase(i0.QueryExecutor e) : super(e);
  $MyDatabaseManager get managers => $MyDatabaseManager(this);
  late final i1.$CategoriesTable categories = i1.$CategoriesTable(this);
  late final i1.$TodoItemsTable todoItems = i1.$TodoItemsTable(this);
  i0.Selectable<CategoriesWithCountResult> categoriesWithCount() {
    return customSelect(
        'SELECT *, (SELECT COUNT(*) FROM todo_items WHERE category = c.id) AS amount FROM categories AS c',
        variables: [],
        readsFrom: {
          todoItems,
          categories,
        }).map((i0.QueryRow row) => CategoriesWithCountResult(
          id: row.read<int>('id'),
          name: row.read<String>('name'),
          amount: row.read<int>('amount'),
        ));
  }

  @override
  Iterable<i0.TableInfo<i0.Table, Object?>> get allTables =>
      allSchemaEntities.whereType<i0.TableInfo<i0.Table, Object?>>();
  @override
  List<i0.DatabaseSchemaEntity> get allSchemaEntities =>
      [categories, todoItems];
}

class $$CategoriesTableFilterComposer
    extends i0.FilterComposer<i0.GeneratedDatabase, i1.$CategoriesTable> {
  $$CategoriesTableFilterComposer(super.db, super.table);
  i0.ColumnFilters<int> get id => i0.ColumnFilters($table.id);
  i0.ColumnFilters<String> get name => i0.ColumnFilters($table.name);
  i0.ComposableFilter todoItemsRefs(
      i0.ComposableFilter Function($$TodoItemsTableFilterComposer f) f) {
    return $composeWithJoins(
        $db: $db,
        $table: $table,
        referencedTable: i2.ReadDatabaseContainer($db)
            .resultSet<i1.$TodoItemsTable>('todo_items'),
        getCurrentColumn: (f) => f.id,
        getReferencedColumn: (f) => f.category,
        getReferencedComposer: (db, table) =>
            $$TodoItemsTableFilterComposer(db, table),
        builder: f);
  }
}

class $$CategoriesTableOrderingComposer
    extends i0.OrderingComposer<i0.GeneratedDatabase, i1.$CategoriesTable> {
  $$CategoriesTableOrderingComposer(super.db, super.table);
  i0.ColumnOrderings<int> get id => i0.ColumnOrderings($table.id);
  i0.ColumnOrderings<String> get name => i0.ColumnOrderings($table.name);
}

class $$CategoriesTableProcessedTableManager extends i0.ProcessedTableManager<
    i0.GeneratedDatabase,
    i1.$CategoriesTable,
    i1.Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableProcessedTableManager,
    $$CategoriesTableInsertCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder> {
  const $$CategoriesTableProcessedTableManager(super.$state);
}

typedef $$CategoriesTableInsertCompanionBuilder = i1.CategoriesCompanion
    Function({
  i0.Value<int> id,
  required String name,
});
typedef $$CategoriesTableUpdateCompanionBuilder = i1.CategoriesCompanion
    Function({
  i0.Value<int> id,
  i0.Value<String> name,
});

class $$CategoriesTableTableManager extends i0.RootTableManager<
    i0.GeneratedDatabase,
    i1.$CategoriesTable,
    i1.Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableProcessedTableManager,
    $$CategoriesTableInsertCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder> {
  $$CategoriesTableTableManager(
      i0.GeneratedDatabase db, i1.$CategoriesTable table)
      : super(i0.TableManagerState(
            db: db,
            table: table,
            filteringComposer: $$CategoriesTableFilterComposer(db, table),
            orderingComposer: $$CategoriesTableOrderingComposer(db, table),
            getChildManagerBuilder: (p0) =>
                $$CategoriesTableProcessedTableManager(p0),
            getUpdateCompanionBuilder: ({
              i0.Value<int> id = const i0.Value.absent(),
              i0.Value<String> name = const i0.Value.absent(),
            }) =>
                i1.CategoriesCompanion(
                  id: id,
                  name: name,
                ),
            getInsertCompanionBuilder: ({
              i0.Value<int> id = const i0.Value.absent(),
              required String name,
            }) =>
                i1.CategoriesCompanion.insert(
                  id: id,
                  name: name,
                )));
}

class $$TodoItemsTableFilterComposer
    extends i0.FilterComposer<i0.GeneratedDatabase, i1.$TodoItemsTable> {
  $$TodoItemsTableFilterComposer(super.db, super.table);
  i0.ColumnFilters<int> get id => i0.ColumnFilters($table.id);
  i0.ColumnFilters<String> get title => i0.ColumnFilters($table.title);
  i0.ColumnFilters<String> get content => i0.ColumnFilters($table.content);
  i0.ColumnFilters<int> get categoryId => i0.ColumnFilters($table.category);
  i0.ComposableFilter category(
      i0.ComposableFilter Function($$CategoriesTableFilterComposer f) f) {
    return $composeWithJoins(
        $db: $db,
        $table: $table,
        referencedTable: i2.ReadDatabaseContainer($db)
            .resultSet<i1.$CategoriesTable>('categories'),
        getCurrentColumn: (f) => f.category,
        getReferencedColumn: (f) => f.id,
        getReferencedComposer: (db, table) =>
            $$CategoriesTableFilterComposer(db, table),
        builder: f);
  }

  i0.ColumnFilters<DateTime> get dueDate => i0.ColumnFilters($table.dueDate);
}

class $$TodoItemsTableOrderingComposer
    extends i0.OrderingComposer<i0.GeneratedDatabase, i1.$TodoItemsTable> {
  $$TodoItemsTableOrderingComposer(super.db, super.table);
  i0.ColumnOrderings<int> get id => i0.ColumnOrderings($table.id);
  i0.ColumnOrderings<String> get title => i0.ColumnOrderings($table.title);
  i0.ColumnOrderings<String> get content => i0.ColumnOrderings($table.content);
  i0.ColumnOrderings<int> get categoryId => i0.ColumnOrderings($table.category);
  i0.ComposableOrdering category(
      i0.ComposableOrdering Function($$CategoriesTableOrderingComposer o) o) {
    return $composeWithJoins(
        $db: $db,
        $table: $table,
        referencedTable: i2.ReadDatabaseContainer($db)
            .resultSet<i1.$CategoriesTable>('categories'),
        getCurrentColumn: (f) => f.category,
        getReferencedColumn: (f) => f.id,
        getReferencedComposer: (db, table) =>
            $$CategoriesTableOrderingComposer(db, table),
        builder: o);
  }

  i0.ColumnOrderings<DateTime> get dueDate =>
      i0.ColumnOrderings($table.dueDate);
}

class $$TodoItemsTableProcessedTableManager extends i0.ProcessedTableManager<
    i0.GeneratedDatabase,
    i1.$TodoItemsTable,
    i1.TodoItem,
    $$TodoItemsTableFilterComposer,
    $$TodoItemsTableOrderingComposer,
    $$TodoItemsTableProcessedTableManager,
    $$TodoItemsTableInsertCompanionBuilder,
    $$TodoItemsTableUpdateCompanionBuilder> {
  const $$TodoItemsTableProcessedTableManager(super.$state);
}

typedef $$TodoItemsTableInsertCompanionBuilder = i1.TodoItemsCompanion
    Function({
  i0.Value<int> id,
  required String title,
  required String content,
  i0.Value<int?> category,
  i0.Value<DateTime?> dueDate,
});
typedef $$TodoItemsTableUpdateCompanionBuilder = i1.TodoItemsCompanion
    Function({
  i0.Value<int> id,
  i0.Value<String> title,
  i0.Value<String> content,
  i0.Value<int?> category,
  i0.Value<DateTime?> dueDate,
});

class $$TodoItemsTableTableManager extends i0.RootTableManager<
    i0.GeneratedDatabase,
    i1.$TodoItemsTable,
    i1.TodoItem,
    $$TodoItemsTableFilterComposer,
    $$TodoItemsTableOrderingComposer,
    $$TodoItemsTableProcessedTableManager,
    $$TodoItemsTableInsertCompanionBuilder,
    $$TodoItemsTableUpdateCompanionBuilder> {
  $$TodoItemsTableTableManager(
      i0.GeneratedDatabase db, i1.$TodoItemsTable table)
      : super(i0.TableManagerState(
            db: db,
            table: table,
            filteringComposer: $$TodoItemsTableFilterComposer(db, table),
            orderingComposer: $$TodoItemsTableOrderingComposer(db, table),
            getChildManagerBuilder: (p0) =>
                $$TodoItemsTableProcessedTableManager(p0),
            getUpdateCompanionBuilder: ({
              i0.Value<int> id = const i0.Value.absent(),
              i0.Value<String> title = const i0.Value.absent(),
              i0.Value<String> content = const i0.Value.absent(),
              i0.Value<int?> category = const i0.Value.absent(),
              i0.Value<DateTime?> dueDate = const i0.Value.absent(),
            }) =>
                i1.TodoItemsCompanion(
                  id: id,
                  title: title,
                  content: content,
                  category: category,
                  dueDate: dueDate,
                ),
            getInsertCompanionBuilder: ({
              i0.Value<int> id = const i0.Value.absent(),
              required String title,
              required String content,
              i0.Value<int?> category = const i0.Value.absent(),
              i0.Value<DateTime?> dueDate = const i0.Value.absent(),
            }) =>
                i1.TodoItemsCompanion.insert(
                  id: id,
                  title: title,
                  content: content,
                  category: category,
                  dueDate: dueDate,
                )));
}

class $MyDatabaseManager {
  final $MyDatabase _db;
  $MyDatabaseManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$TodoItemsTableTableManager get todoItems =>
      $$TodoItemsTableTableManager(_db, _db.todoItems);
}

class CategoriesWithCountResult {
  final int id;
  final String name;
  final int amount;
  CategoriesWithCountResult({
    required this.id,
    required this.name,
    required this.amount,
  });
}
