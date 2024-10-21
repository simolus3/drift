// ignore_for_file: invalid_use_of_internal_member, unused_local_variable, unused_element, avoid_single_cascade_in_expression_statements

import 'package:drift/drift.dart';
import 'package:drift_docs/snippets/modular/schema_inspection.dart';
import 'package:drift_docs/snippets/setup/database.dart';

part 'manager.g.dart';

// @DriftDatabase(tables: [TodoItems, TodoCategory, Groups, Users])
// class Database extends _$Database {
//   Database(super.e);
//   @override
//   int get schemaVersion => 1;
// }

// extension ManagerExamples on Database {
//   // #docregion manager_create
//   Future<void> createTodoItem() async {
//     // Create a new item
//     await managers.todoItems
//         .create((o) => o(title: 'Title', content: 'Content'));

//     // We can also use `mode` and `onConflict` parameters, just
//     // like in the `[InsertStatement.insert]` method on the table
//     await managers.todoItems.create(
//         (o) => o(title: 'Title', content: 'New Content'),
//         mode: InsertMode.replace);

//     // We can also create multiple items at once
//     await managers.todoItems.bulkCreate(
//       (o) => [
//         o(title: 'Title 1', content: 'Content 1'),
//         o(title: 'Title 2', content: 'Content 2'),
//       ],
//     );
//   }
//   // #enddocregion manager_create

//   // #docregion manager_update
//   Future<void> updateTodoItems() async {
//     // Update all items
//     await managers.todoItems.update((o) => o(content: Value('New Content')));

//     // Update multiple items
//     await managers.todoItems
//         .filter((f) => f.id.isIn([1, 2, 3]))
//         .update((o) => o(content: Value('New Content')));
//   }
//   // #enddocregion manager_update

//   // #docregion manager_replace
//   Future<void> replaceTodoItems() async {
//     // Replace a single item
//     var obj = await managers.todoItems.filter((o) => o.id(1)).getSingle();
//     obj = obj.copyWith(content: 'New Content');
//     await managers.todoItems.replace(obj);

//     // Replace multiple items
//     var objs =
//         await managers.todoItems.filter((o) => o.id.isIn([1, 2, 3])).get();
//     objs = objs.map((o) => o.copyWith(content: 'New Content')).toList();
//     await managers.todoItems.bulkReplace(objs);
//   }
//   // #enddocregion manager_replace

//   // #docregion manager_delete
//   Future<void> deleteTodoItems() async {
//     // Delete all items
//     await managers.todoItems.delete();

//     // Delete a single item
//     await managers.todoItems.filter((f) => f.id(5)).delete();
//   }
//   // #enddocregion manager_delete

//   Future<void> orderWithType() async {
//     // Order all items by their creation date in ascending order
//     managers.todoItems.orderBy((o) => o.createdAt.asc());

//     // Order all items by their title in ascending order and then by their content in ascending order
//     managers.todoItems.orderBy((o) => o.title.asc() & o.content.asc());
//   }

// // #docregion manager_count
//   Future<void> count() async {
//     // Count all items
//     await managers.todoItems.count();

//     // Count all items with a title of "Title"
//     await managers.todoItems.filter((f) => f.title("Title")).count();
//   }
// // #enddocregion manager_count

// // #docregion manager_exists
//   Future<void> exists() async {
//     // Check if any items exist
//     await managers.todoItems.exists();

//     // Check if any items with a title of "Title" exist
//     await managers.todoItems.filter((f) => f.title("Title")).exists();
//   }
// // #enddocregion manager_exists

// // #docregion manager_filter_forward_references
//   Future<void> relationalFilter() async {
//     // Get all items with a category description of "School"
//     managers.todoItems.filter((f) => f.category.description("School"));

//     // These can be combined with other filters
//     // For example, get all items with a title of "Title" or a category description of "School"
//     await managers.todoItems
//         .filter(
//           (f) => f.title("Title") | f.category.description("School"),
//         )
//         .exists();
//   }
// // #enddocregion manager_filter_forward_references

// // #docregion manager_filter_back_references
//   Future<void> reverseRelationalFilter() async {
//     // Get the category that has a todo item with an id of 1
//     managers.todoCategory.filter((f) => f.todoItemsRefs((f) => f.id(1)));

//     // These can be combined with other filters
//     // For example, get all categories with a description of "School" or a todo item with an id of 1
//     managers.todoCategory.filter(
//       (f) => f.description("School") | f.todoItemsRefs((f) => f.id(1)),
//     );
//   }
// // #enddocregion manager_filter_back_references

// // #docregion manager_filter_custom_back_references
//   Future<void> reverseNamedRelationalFilter() async {
//     // Get all users who are administrators of a group with a name containing "Business"
//     // or who own a group with an id of 1, 2, 4, or 5
//     managers.users.filter(
//       (f) =>
//           f.administeredGroups((f) => f.name.contains("Business")) |
//           f.ownedGroups((f) => f.id.isIn([1, 2, 4, 5])),
//     );
//   }
// // #enddocregion manager_filter_custom_back_references

// // #docregion manager_prefetch_references
//   Future<void> referencesPrefetch() async {
//     /// Get each todo, along with a its categories
//     final categoriesWithReferences = await managers.todoItems
//         .withReferences(
//           (prefetch) => prefetch(category: true),
//         )
//         .get();
//     for (final (todo, refs) in categoriesWithReferences) {
//       final category = refs.category?.prefetchedData?.firstOrNull;
//       // No longer needed
//       // final category = await refs.category?.getSingle();
//     }

//     /// This also works in the reverse
//     final todosWithRefs = await managers.todoCategory
//         .withReferences((prefetch) => prefetch(todoItemsRefs: true))
//         .get();
//     for (final (category, refs) in todosWithRefs) {
//       final todos = refs.todoItemsRefs.prefetchedData;
//       // No longer needed
//       //final todos = await refs.todoItemsRefs.get();
//     }
//   }
// // #enddocregion manager_prefetch_references

//   Future<void> referencesPrefetchStream() async {
// // #docregion manager_prefetch_references_stream
//     /// Get each todo, along with a its categories
//     managers.todoCategory
//         .withReferences((prefetch) => prefetch(todoItemsRefs: true, user: true))
//         .watch()
//         .listen(
//       (catWithRefs) {
//         for (final (cat, refs) in catWithRefs) {
//           // Updates to the user table will trigger a query
//           final users = refs.user?.prefetchedData;

//           // However, updates to the TodoItems table will not trigger a query
//           final todos = refs.todoItemsRefs.prefetchedData;
//         }
//       },
//     );
// // #enddocregion manager_prefetch_references_stream
//   }
// }

// #docregion manager_filter_extensions
// Extend drifts built-in filters by combining the existing filters to create a new one
// or by creating a new filter from scratch
extension After2000Filter on ColumnFilters<DateTime> {
  // Create a new filter by combining existing filters
  Expression<bool> after2000orBefore1900() =>
      isAfter(DateTime(2000)) | isBefore(DateTime(1900));

  // Create a new filter from scratch using the `column` property
  Expression<bool> filterOnUnixEpoch(int value) =>
      $composableFilter(column.unixepoch.equals(value));
}

Future<void> filterWithExtension(AppDatabase db) async {
  // Use the custom filters on any column that is of type DateTime
  db.managers.todoItems.filter((f) => f.createdAt.after2000orBefore1900());

  // Use the custom filter on the `unixepoch` column
  db.managers.todoItems.filter((f) => f.createdAt.filterOnUnixEpoch(0));
}
// #enddocregion manager_filter_extensions

// Extend drifts built-in orderings by create a new ordering from scratch
extension After2000Ordering on ColumnOrderings<DateTime> {
  ComposableOrdering byUnixEpoch() => ColumnOrderings(column.unixepoch).asc();
}

Future<void> orderingWithExtension(AppDatabase db) async {
  // Use the custom orderings on any column that is of type DateTime
  db.managers.todoItems.orderBy((f) => f.createdAt.byUnixEpoch());
}

// #docregion manager_custom_filter
// Extend the generated table filter composer to add a custom filter
extension NoContentOrBefore2000FilterX on $$TodoItemsTableFilterComposer {
  Expression<bool> noContentOrBefore2000() =>
      (content.isNull() | createdAt.isBefore(DateTime(2000)));
}

Future<void> customFilter(AppDatabase db) async {
  // Use the custom filter on the `TodoItems` table
  db.managers.todoItems.filter((f) => f.noContentOrBefore2000());
}
// #enddocregion manager_custom_filter

// #docregion manager_custom_ordering
// Extend the generated table filter composer to add a custom filter
extension ContentThenCreationDataX on $$TodoItemsTableOrderingComposer {
  ComposableOrdering contentThenCreatedAt() => content.asc() & createdAt.asc();
}

Future<void> customOrdering(AppDatabase db) async {
  // Use the custom ordering on the `TodoItems` table
  db.managers.todoItems.orderBy((f) => f.contentThenCreatedAt());
}
// #enddocregion manager_custom_ordering

void _managerAnnotations(AppDatabase db) async {
  // #docregion manager_annotations
  // First create an computed field with an expression you want to use
  final titleLengthField =
      db.managers.todoItems.computedField((o) => o.title.length);

  /// Create a copy of the manager with the computed fields you want to use
  final manager = db.managers.todoItems.withFields([titleLengthField]);

  // Then use the computed field in a filter
  // This will filter all items whose title has exactly 10 characters
  manager.filter((f) => titleLengthField.filter(10));

  // You can also use the computed field in an ordering
  // This will order all items by the length of their title in ascending order
  manager.orderBy((o) => titleLengthField.order.asc());

  /// You can read the result of the computed field too
  for (final (item, refs) in await manager.get()) {
    final titleLength = titleLengthField.read(refs);
    print('Item ${item.id} has a title length of $titleLength');
  }
// #enddocregion manager_annotations
}

void _managerReferencedAnnotations(AppDatabase db) async {
  // #docregion referenced_annotations
  // This computed field will get the name of the user of this todo
  final todoUserName =
      db.managers.todoItems.computedField((o) => o.category.user.name);

  /// Create a copy of the manager with the computed fields you want to use
  final manager = db.managers.todoItems.withFields([todoUserName]);

  /// You can read the result of the computed field too
  for (final (item, refs) in await manager.get()) {
    final userName = todoUserName.read(refs);
    print('Item ${item.id} has a user with the name $userName');
  }
  // #enddocregion referenced_annotations
}

void _managerAggregatedAnnotations(AppDatabase db) async {
  // #docregion aggregated_annotations
  // You can aggregate over multiple rows in a related table
  // to perform calculations on them
  final todoCountcomputedField = db.managers.todoCategory
      .computedField((o) => o.mainCategory((o) => o.id).count());

  /// Create a copy of the manager with the computed fields you want to use
  final manager = db.managers.todoCategory.withFields([todoCountcomputedField]);

  /// Read the result of the computed field
  for (final (category, refs) in await manager.get()) {
    final todoCount = todoCountcomputedField.read(refs);
    print('Category ${category.id} has $todoCount todos');
  }
  // #enddocregion aggregated_annotations
}

Future<void> sampleExample(AppDatabase db) async {
  // #docregion manager_example
  // Fetch all items with a title of "Hello World"
  // ordered by their creation date
  await db.managers.todoItems
      .filter((f) => f.title("Hello World"))
      .orderBy((o) => o.createdAt.asc())
      .get();

  // Delete all items
  await db.managers.todoItems.delete();

  // Update todo item with an id of 1 to have a title of "New Title"
  await db.managers.todoItems
      .filter((f) => f.id(1))
      .update((o) => o(title: Value("New Title")));
  // #enddocregion manager_example
  // #docregion core_example
  // Fetch all items with a title of "Hello World"
  // ordered by their creation date
  await (db.select(db.todoItems)
        ..where((tbl) => tbl.title.equals("Hello World"))
        ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
      .get();

  // Delete all items
  await db.delete(db.todoItems).go();

  // Update todo item with an id of 1 to have a title of "New Title"
  await (db.update(db.todoItems)..where((tbl) => tbl.id.equals(1)))
      .write(TodoItemsCompanion(title: Value("New Title")));

  // #enddocregion core_example
}

Future<void> selectTodoItems(AppDatabase db) async {
  // #docregion manager_select
  // Retrieve all items
  await db.managers.todoItems.get();

  // Retrieve a single item
  await db.managers.todoItems.filter((f) => f.id(1)).getSingle();

  // Retrieve a single item which may not exist
  await db.managers.todoItems.filter((f) => f.id(1)).getSingleOrNull();
  // #enddocregion manager_select
  // #docregion core_select
  // Retrieve all items
  await db.select(db.todoItems).get();

  // Retrieve a single item
  await (db.select(db.todoItems)..where((tbl) => tbl.id.equals(1))).getSingle();

  // Retrieve a single item which may not exist
  await (db.select(db.todoItems)..where((tbl) => tbl.id.equals(1)))
      .getSingleOrNull();
  // #enddocregion core_select

  // #docregion manager_watch
  // Watch all items
  db.managers.todoItems.watch();

  // Watch a single item
  db.managers.todoItems.filter((f) => f.id(1)).watchSingle();

  // Watch a single item which may not exist
  db.managers.todoItems.filter((f) => f.id(1)).watchSingleOrNull();

  // #enddocregion manager_watch
  // #docregion core_watch
  // Watch all items
  db.select(db.todoItems).watch();

  // Watch a single item
  (db.select(db.todoItems)..where((tbl) => tbl.id.equals(1))).watch();

  // Watch a single item which may not exist
  (db.select(db.todoItems)..where((tbl) => tbl.id.equals(1)))
      .watchSingleOrNull();
  // #enddocregion core_watch

  // #docregion manager_limit
  // Get 1st 10 items
  await db.managers.todoItems.limit(10).get();

  // Get the next 10 items
  await db.managers.todoItems.limit(10, offset: 10).get();
  // #enddocregion manager_limit
  // #docregion core_limit
  // Get 1st 10 items
  await (db.select(db.todoItems)..limit(10)).get();

  // Get the next 10 items
  await (db.select(db.todoItems)..limit(10, offset: 10)).get();
  // #enddocregion core_limit
}

Future<void> filterTodoItems(AppDatabase db) async {
  // #docregion manager_filter
  // All items with a title of "Hello World"
  db.managers.todoItems.filter(
    (f) => f.title("Hello World"),
  );

  // All items with a title that is not "Hello World"
  db.managers.todoItems.filter(
    (f) => f.title("Hello World").not(), // (1)!
  );

  // All items with a title of "Hello World" AND content of "Content"
  db.managers.todoItems.filter(
    (f) =>
        f.title("Hello World") & // (2)!
        f.content("Content"),
  );

  // All items with a title of "Hello World" OR content of "Content"
  db.managers.todoItems.filter(
    (f) =>
        f.title("Hello World") | // (3)!
        f.content("Content"),
  );

  // Group filters using parentheses
  db.managers.todoItems.filter(
    (f) =>
        (f.title("Hello World") | f.content("Content")) &
        f.createdAt.isAfter(DateTime(2000)),
  );
  // #enddocregion manager_filter

  // #docregion core_filter
  // All items with a title of "Hello World"
  db.select(db.todoItems)
    ..where(
      (tbl) => tbl.title.equals("Hello World"),
    );

  // All items with a title that is not "Hello World"
  db.select(db.todoItems)
    ..where(
      (tbl) => tbl.title.equals("Hello World").not(), // (1)!
    );

  // All items with a title of "Hello World" AND content of "Content"
  db.select(db.todoItems)
    ..where(
      (tbl) =>
          tbl.title.equals("Hello World") & // (2)!
          tbl.content.equals("Content"),
    );

  // All items with title "Hello World" OR content "Content"
  db.select(db.todoItems)
    ..where(
      (tbl) =>
          tbl.title.equals("Hello World") | // (3)!
          tbl.content.equals("Content"),
    );

  // Group filters using parentheses
  db.select(db.todoItems)
    ..where(
      (tbl) =>
          (tbl.title.equals("Hello World") | tbl.content.equals("Content")) &
          tbl.createdAt.isBiggerThanValue(DateTime(2000)),
    );
  // #enddocregion core_filter

  // #docregion manager_complex_filter
  // All items with a title of "Title" and content of "Content"
  db.managers.todoItems.filter((f) => f.title("Title") & f.content("Content"));

  /// Todos that:
  /// 1. Have a title that is not "Title"
  /// OR
  /// 2. Have no content and start with "Hello World"
  db.managers.todoItems.filter(
    (f) =>
        f.title("Title").not() |
        (f.content.isNull() & f.content.startsWith("Hello World")),
  );
  // #enddocregion manager_complex_filter

  // #docregion core_complex_filter
  // All items with a title of "Title" and content of "Content"
  db.select(db.todoItems)
    ..where((tbl) => tbl.title.equals("Title") & tbl.content.equals("Content"));

  /// Todos that:
  /// 1. Have a title that is not "Title"
  /// OR
  /// 2. Have no content and start with "Hello World"
  db.select(db.todoItems)
    ..where(
      (tbl) =>
          tbl.title.equals("Title").not() |
          (tbl.content.isNull() & tbl.content.like("Hello World%")),
    );
  // #enddocregion core_complex_filter
}

Future<void> orderWithType(AppDatabase db) async {
  // #docregion manager_ordering
  // Order all items by their creation date in ascending order
  db.managers.todoItems.orderBy((o) => o.createdAt.asc());

  // Order all items by their title in ascending order and
  // then by their content in ascending order
  db.managers.todoItems.orderBy((o) =>
      o.title.asc() & // (1)!
      o.content.asc());
  // #enddocregion manager_ordering
  // #docregion core_ordering
  // Order all items by their creation date in ascending order
  db.select(db.todoItems).orderBy([
    (tbl) => OrderingTerm.asc(tbl.createdAt),
  ]);

  // Order all items by their title in ascending order and
  // then by their content in ascending order
  db.select(db.todoItems).orderBy([
    (tbl) => OrderingTerm.asc(tbl.title),
    (tbl) => OrderingTerm.asc(tbl.content),
  ]);
  // #enddocregion core_ordering
}

Future<void> _query29(AppDatabase db) async {
  // #docregion joins
  // Build a query with a left outer join to fetch the category for each item
  final query = db.select(db.todoItems).join([
    leftOuterJoin(
      db.todoCategory,
      db.todoCategory.id.equalsExp(db.todoItems.category),
    )
  ]);
  // #enddocregion joins
}

Future<void> _query30(AppDatabase db) async {
  // #docregion core_read_references
  // Build a query with a left outer join to fetch the category for each item
  final query = db.select(db.todoItems).join([
    leftOuterJoin(
      db.todoCategory,
      db.todoCategory.id.equalsExp(db.todoItems.category),
    )
  ]);

  // The query returns a list of `TypedResult` objects
  // Use the `readTable`  method to extract the data from the result
  for (final result in await query.get()) {
    final todo = result.readTable(db.todoItems);
    final category = result.readTableOrNull(db.todoCategory); // (1)!
  }
  // #enddocregion core_read_references
}

Future<void> _query31(AppDatabase db) async {
  // #docregion core_filter_references
  // Build a query with a left outer join to fetch the category for each item
  final query = db.select(db.todoItems).join([
    leftOuterJoin(
      db.todoCategory,
      db.todoCategory.id.equalsExp(db.todoItems.category),
      useColumns: false, // (1)!
    )
  ]);

  // Filter the query to only return items with a category description of "School"
  query.where(db.todoCategory.description.equals("School"));

  // Execute the query using `map` together with `readTable` to extract the data
  // from the `TypedResult` objects
  final results =
      await query.map((result) => result.readTable(db.todoItems)).get();
  // #enddocregion core_filter_references
}

Future<void> _query32(AppDatabase db) async {
  // #docregion core_filter_references_alias
  // Create aliases for the category table
  final mainCategory = db.todoCategory.createAlias('mainCategory');
  final secondaryCategory = db.todoCategory.createAlias('secondaryCategory');

  // Create a select statement with the joins
  final query = db.select(db.todoItems).join([
    leftOuterJoin(
        mainCategory,
        // Use the aliased tables to join the category table
        mainCategory.id.equalsExp(db.todoItems.category),
        useColumns: false),
    leftOuterJoin(
        secondaryCategory,
        // Use the aliased tables to join the category tabl
        secondaryCategory.id.equalsExp(db.todoItems.secondaryCategory),
        useColumns: false),
  ]);

  // Use the aliased tables to filter on the description of the main and secondary category
  query.where(mainCategory.description.equals("School") |
      secondaryCategory.description.equals("School"));

  // Execute the query using `map` together with `readTable` to extract the data
  // from the `TypedResult` objects
  final results =
      await query.map((result) => result.readTable(db.todoItems)).get();
  // #enddocregion core_filter_references_alias
}

Future<void> _query33(AppDatabase db) async {
  // #docregion core_aggregates
  // This expression counts todo items
  final todoItemCountColumn = db.todoItems.id.count();

  // This expression calculates the average age of todo items
  final averageAgeColumn = db.todoItems.createdAt.groupConcat();

  // Create a select statement with the joins
  final query = db.select(db.todoItems).join([
    leftOuterJoin(
        db.todoCategory, db.todoCategory.id.equalsExp(db.todoItems.category)),
  ]);

  // Add the count expression to the query
  query.addColumns([todoItemCountColumn, averageAgeColumn]);

  // We want this count to be performed for each individual category
  query.groupBy([db.todoCategory.id]);

  // The query returns a list of `TypedResult` objects
  // Use the `readTable` & `read` methods to extract the data from the result
  for (final result in await query.get()) {
    final todo = result.readTable(db.todoItems);
    final count = result.read(todoItemCountColumn);
    final averagedAge = result.read(averageAgeColumn);
  }
  // #enddocregion core_aggregates
}

Future<void> _query34(AppDatabase db) async {
  // #docregion core_subquery
  // Build a query which returns the 10 longest todos
  // This will be used a subquery for the main query
  final longestTodos = Subquery(
    db.select(db.todoItems)
      ..orderBy([(row) => OrderingTerm.desc(row.title.length)])
      ..limit(10),
    'longestTodos',
  );

  // Build a query which is only joining the 10 longest todos
  final query = db.select(db.todoCategory).join(
    [
      innerJoin(
        longestTodos,
        // Instead of db.todoItems.category.equalsExp(db.todoCategory.id),
        // we use .ref() to access the category column in the subquery
        longestTodos.ref(db.todoItems.category).equalsExp(db.todoCategory.id),
        useColumns: false,
      )
    ],
  );

  // To count how many entries in longestTodos were found for each category
  // we use Subquery.ref to read from a column in a subquery
  final itemCount = longestTodos.ref(db.todoItems.id).count();

  // Add the count expression to the query
  query.addColumns([itemCount]);

  // We want this count to be performed for each individual category
  query.groupBy([db.todoCategory.id]);

  // The query returns a list of `TypedResult` objects
  // Use the `readTable` & `read` methods to extract the data from the result
  for (final result in await query.get()) {
    final category = result.readTable(db.todoCategory);
    final longestTodosCount = result.read(itemCount);
  }
  // #enddocregion core_subquery
}

Future<void> _query38(AppDatabase db) async {
  // #docregion manager_filter_references
  final schoolTodos = await db.managers.todoItems
      // Filter all items with a category description of "School"
      .filter((f) => f.category.description("School"))
      // Order the results alphabetically by
      // 1. The category description and
      // 2. The todo title
      .orderBy((o) => o.category.description.asc() & o.title.asc())
      .get();

  // Any category which contains a todo with a title of "Hello World"
  final categoriesWithHelloWorld = await db.managers.todoCategory
      .filter((f) => f.mainCategory((o) => o.title("Hello World")))
      .get();
  // #enddocregion manager_filter_references
}

Future<void> _query89(AppDatabase db) async {
  // #docregion manager_references_read
  // Get all todo items with their category prefetched
  final results = await db.managers.todoItems
      .withReferences((prefetch) => prefetch(category: true)) // (1)!
      .get();

  for (final (todo, refs) in results) {
    // Access the prefetched category
    final category = refs.category?.prefetchedData?.firstOrNull;
  }

  // #enddocregion manager_references_read
}

Future<void> _query88(AppDatabase db) async {
  // #docregion manager_references_read
  // NOT RECOMMENDED: This will trigger a query for each item
  final results = await db.managers.todoItems.withReferences().get();
  for (final (todo, refs) in results) {
    final category = await refs.category?.getSingle();
  }
  // #enddocregion manager_references_read
}
