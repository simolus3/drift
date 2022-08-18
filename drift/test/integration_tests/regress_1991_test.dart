import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils/test_utils.dart';

// Regression test for https://github.com/simolus3/drift/issues/1991

Future<int?> _getCategoryIdByDescription(
    TodoDb appDatabase, String description) async {
  const q = "SELECT id FROM categories WHERE desc = ?";
  final row = await appDatabase.customSelect(
    q,
    variables: [Variable<String>(description)],
  ).getSingleOrNull();
  return row?.read("id");
}

void main() {
  test('type inference for nullable call in async function', () async {
    final db = TodoDb.connect(testInMemoryDatabase());
    addTearDown(db.close);

    final categoryDescription = 'category description';
    expect(await _getCategoryIdByDescription(db, categoryDescription), isNull);

    await db.categories.insertOne(
        CategoriesCompanion.insert(description: categoryDescription));

    // Search the category we just inserted
    expect(
        await _getCategoryIdByDescription(db, categoryDescription), isNotNull);
  });
}
