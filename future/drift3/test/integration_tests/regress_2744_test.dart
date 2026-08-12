import 'package:async/async.dart';
import 'package:drift3/drift.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils.dart';

void main() {
  test('updates after transaction', () async {
    // Regression test for https://github.com/simolus3/drift/issues/2744
    final db = TodoDb(testInMemoryDatabase());
    final categories = StreamQueue(db.categoriesQueries.all().watch());

    await expectLater(categories, emits(isEmpty));
    await db.categoriesQueries.insertOne(
      CategoriesCompanion.insert(description: 'desc1'),
    );
    await expectLater(categories, emits(hasLength(1)));

    await db.delete(db.categories).go();
    await db.batch((batch) {
      batch.insert(
        db.categories,
        CategoriesCompanion.insert(description: 'desc2'),
      );
    });

    await expectLater(
      categories,
      emits([
        isA<Category>().having((e) => e.description, 'description', 'desc2'),
      ]),
    );
  });
}
