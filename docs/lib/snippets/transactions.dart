import 'package:drift/drift.dart';
import 'tables/filename.dart';

extension Snippets on MyDatabase {
  // #docregion deleteCategory
  Future<void> deleteCategory(Category category) {
    return transaction(() async {
      // first, move the affected todo entries back to the default category
      await (update(todos)..where((row) => row.category.equals(category.id)))
          .write(const TodosCompanion(category: Value(null)));

      // then, delete the category
      await delete(categories).delete(category);
    });
  }
  // #enddocregion deleteCategory

  // #docregion nested
  Future<void> nestedTransactions() async {
    await transaction(() async {
      await into(categories)
          .insert(CategoriesCompanion.insert(description: 'first'));

      // this is a nested transaction:
      await transaction(() async {
        // At this point, the first category is visible
        await into(categories)
            .insert(CategoriesCompanion.insert(description: 'second'));
        // Here, the second category is only visible inside this nested
        // transaction.
      });

      // At this point, the second category is visible here as well.

      try {
        await transaction(() async {
          // At this point, both categories are visible
          await into(categories)
              .insert(CategoriesCompanion.insert(description: 'third'));
          // The third category is only visible here.
          throw Exception('Abort in the second nested transaction');
        });
      } on Exception {
        // We're catching the exception so that this transaction isn't reverted
        // as well.
      }

      // At this point, the third category is NOT visible, but the other two
      // are. The transaction is in the same state as before the second nested
      // `transaction()` call.
    });

    // After the transaction, two categories are visible.
  }
  // #enddocregion nested
}
