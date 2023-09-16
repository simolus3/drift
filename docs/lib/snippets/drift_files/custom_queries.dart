import 'package:drift/drift.dart';

import '../_shared/todo_tables.dart';
import '../_shared/todo_tables.drift.dart';
import 'custom_queries.drift.dart';

// #docregion manual
class CategoryWithCount {
  final Category category;
  final int count; // amount of entries in this category

  CategoryWithCount({required this.category, required this.count});
}

// #enddocregion manual

// #docregion setup
@DriftDatabase(
  tables: [TodoItems, Categories],
  queries: {
    'categoriesWithCount': 'SELECT *, '
        '(SELECT COUNT(*) FROM todo_items WHERE category = c.id) AS "amount" '
        'FROM categories c;'
  },
)
class MyDatabase extends $MyDatabase {
  // rest of class stays the same
  // #enddocregion setup
  @override
  int get schemaVersion => 1;

  MyDatabase(QueryExecutor e) : super(e);

  // #docregion run
  Future<void> useGeneratedQuery() async {
    // The generated query can be run once as a future:
    await categoriesWithCount().get();

    // Or multiple times as a stream
    await for (final snapshot in categoriesWithCount().watch()) {
      print('Found ${snapshot.length} category results');
    }
  }

  // #enddocregion run
  // #docregion manual
  // then, in the database class:
  Stream<List<CategoryWithCount>> allCategoriesWithCount() {
    // select all categories and load how many associated entries there are for
    // each category
    return customSelect(
      'SELECT *, (SELECT COUNT(*) FROM todos WHERE category = c.id) AS "amount"'
      ' FROM categories c;',
      // used for the stream: the stream will update when either table changes
      readsFrom: {todoItems, categories},
    ).watch().map((rows) {
      // we get list of rows here. We just have to turn the raw data from the
      // row into a CategoryWithCount instnace. As we defined the Category table
      // earlier, drift knows how to parse a category. The only thing left to do
      // manually is extracting the amount.
      return rows
          .map((row) => CategoryWithCount(
                category: categories.map(row.data),
                count: row.read<int>('amount'),
              ))
          .toList();
    });
  }

// #enddocregion manual

  // #docregion setup
}
// #enddocregion setup
