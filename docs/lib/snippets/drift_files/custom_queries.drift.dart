// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:drift_docs/snippets/_shared/todo_tables.drift.dart' as i1;

abstract class $MyDatabase extends i0.GeneratedDatabase {
  $MyDatabase(i0.QueryExecutor e) : super(e);
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
