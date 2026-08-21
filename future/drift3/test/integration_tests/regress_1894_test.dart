import 'package:drift3_preview/drift.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils.dart';

void main() {
  test('exists subqueries properly reference columns', () async {
    final db = TodoDb(testInMemoryDatabase());
    addTearDown(db.close);

    final nonEmptyId = await db.categoriesQueries.insertOne(
      CategoriesCompanion.insert(description: 'category'),
    );
    await db.todosTableQueries.insertOne(
      TodosTableCompanion.insert(
        content: 'entry',
        category: Value(RowId(nonEmptyId)),
      ),
    );

    final emptyId = await db.categoriesQueries.insertOne(
      CategoriesCompanion.insert(description: 'this category empty YEET'),
    );

    final emptyCategories = await db.emptyCategories();

    expect(emptyCategories, hasLength(1));
    expect(emptyCategories.single.id, emptyId);
  });
}

extension on TodoDb {
  Future<List<Category>> emptyCategories() {
    final hasNoTodo = notExistsQuery(
      select(todosTable)..where((row) => row.category.equalsExp(categories.id)),
    );
    return (select(categories)..where((row) => hasNoTodo)).get();
  }
}
