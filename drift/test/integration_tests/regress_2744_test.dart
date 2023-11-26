import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils/test_utils.dart';

void main() {
  test('updates after transaction', () async {
    // Regression test for https://github.com/simolus3/drift/issues/2744
    final db = TodoDb(testInMemoryDatabase());
    final categories = db.categories.all().watch();

    expect(categories, emits(isEmpty));
    await db.categories
        .insertOne(CategoriesCompanion.insert(description: 'desc1'));
    expect(categories, emits(hasLength(1)));

    await db.categories.deleteAll();
    await db.batch((batch) {
      batch.insert(
          db.categories, CategoriesCompanion.insert(description: 'desc2'));
    });

    expect(
        categories,
        emits([
          isA<Category>().having((e) => e.description, 'description', 'desc2')
        ]));
  });
}
