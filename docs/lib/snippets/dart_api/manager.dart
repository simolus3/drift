// ignore_for_file: invalid_use_of_internal_member, unused_local_variable, unused_element

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/isolate.dart';
import 'package:drift/native.dart';

part 'manager.g.dart';

// #docregion schema
class TodoItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().unique().withLength(min: 6, max: 32)();
  TextColumn get content => text().named('body')();
  IntColumn get category =>
      integer().nullable().references(TodoCategory, #id)();
  DateTimeColumn get createdAt => dateTime().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(Constant(false))();
}

class TodoCategory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get description => text()();
  IntColumn get user => integer().nullable().references(Users, #id)();
}

// #docregion user_group_tables
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

// #enddocregion schema

class Groups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  @ReferenceName("administeredGroups")
  IntColumn get admin => integer().nullable().references(Users, #id)();
  @ReferenceName("ownedGroups")
  IntColumn get owner => integer().references(Users, #id)();
}

// #enddocregion user_group_tables
// #docregion schema
@DriftDatabase(tables: [TodoItems, TodoCategory, Groups, Users])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);
  @override
  int get schemaVersion => 1;
}
// #enddocregion schema

void examples() {
  final db = AppDatabase(NativeDatabase.memory());
  Future<void> createTodoItem() async {
    // #docregion manager_create_single
    // Create a new item
    await db.managers.todoItems
        .create((o) => o(title: 'Title', content: 'Content'));
    // #enddocregion manager_create_single

    // #docregion manager_create_mode
    // We can also use `mode` and `onConflict` parameters.
    await db.managers.todoItems.create(
        (o) => o(title: 'Title', content: 'New Content'),
        mode: InsertMode.insertOrReplace);

    // #enddocregion manager_create_mode
    // #docregion manager_create_multiple
    // We can also create multiple items at once
    await db.managers.todoItems.bulkCreate(
      (o) => [
        o(title: 'Title 1', content: 'Content 1'),
        o(title: 'Title 2', content: 'Content 2'),
      ],
    );
    // #enddocregion manager_create_multiple
  }

  Future<void> updateTodoItems() async {
    final todo = await db.managers.todoItems.filter((f) => f.id(1)).getSingle();

    final todos =
        await db.managers.todoItems.filter((f) => f.id.isIn([1, 2, 3])).get();
    // #docregion manager_update
    // Update a single item
    await db.managers.todoItems
        .filter((f) => f.id(1))
        .update((o) => o(isCompleted: Value(true)));

    // Update a single item by completely replacing it
    await db.managers.todoItems.replace(todo.copyWith(isCompleted: true));

    // Replace multiple items at once
    await db.managers.todoItems
        .bulkReplace(todos.map((e) => e.copyWith(isCompleted: true)));
    // #enddocregion manager_update
  }

  // #docregion manager_replace
  Future<void> replaceTodoItems() async {
    // Replace a single item
    var obj = await db.managers.todoItems.filter((o) => o.id(1)).getSingle();
    obj = obj.copyWith(content: 'New Content');
    await db.managers.todoItems.replace(obj);

    // Replace multiple items
    var objs =
        await db.managers.todoItems.filter((o) => o.id.isIn([1, 2, 3])).get();
    objs = objs.map((o) => o.copyWith(content: 'New Content')).toList();
    await db.managers.todoItems.bulkReplace(objs);
  }
  // #enddocregion manager_replace

  Future<void> deleteTodoItems() async {
    // #docregion manager_delete
    // Delete all items
    await db.managers.todoItems.delete();

    // Delete a single item
    await db.managers.todoItems.filter((f) => f.id(5)).delete();
    // #enddocregion manager_delete
  }

  Future<void> selectTodoItems() async {
    // #docregion retrieve_all
    // Retrieve all todo items
    final todos = await db.managers.todoItems.get();

    // A stream of all the todo items, updated in real-time
    final todoStream = db.managers.todoItems.watch();
    // #enddocregion retrieve_all

    // #docregion retrieve_single
    // Retrieve the item with an id of 1
    await db.managers.todoItems.filter((f) => f.id(1)).getSingle();
    // #enddocregion retrieve_single

    // #docregion retrieve_first
    // Retrieve the first item, or null if there are no items
    await db.managers.todoItems.limit(1).getSingleOrNull();
    // #enddocregion retrieve_first

    // #docregion pagination
    // This will retrieve the first 10 items
    await db.managers.todoItems.get(limit: 10, offset: 0);

    // You can also use `limit` method to achieve the same result
    await db.managers.todoItems.limit(10, offset: 0).get();
    // #enddocregion pagination

    // #docregion pagination-bad
    // This will return all the items, even the first 50
    await db.managers.todoItems.get(offset: 50);
    // #enddocregion pagination-bad
  }

  Future<void> filterAndSort() async {
    // #docregion filter-and-sort-summary
    // All items with a title of "Title"
    db.managers.todoItems.filter((f) => f.title("Title"));

    // Get all items in Category 1
    db.managers.todoItems.filter((f) => f.category.id.equals(1));

    // Sort all items by their creation date in ascending order
    db.managers.todoItems.orderBy((o) => o.createdAt.asc());

    // You can chain filters and orderings
    db.managers.todoItems
        // All items in Category 1 created after 2023
        .filter((f) =>
            f.category.id.equals(1) & f.createdAt.isAfter(DateTime(2023)))
        // Then sort them by their title and then by their creation date.
        .orderBy((o) => o.title.asc() & o.createdAt.asc());
    // #enddocregion filter-and-sort-summary
  }

  Future<void> usage() async {
    // #docregion filter-and-sort-usage
    // Will only retrieve items with a title of "Title"
    final titleQuery = db.managers.todoItems.filter((f) => f.title("Title"));

    // Retrieve the filtered items
    await titleQuery.get();

    // Delete the filtered items
    await titleQuery.delete();

    // Update the filtered items
    await titleQuery.update((o) => o(isCompleted: Value(true)));
    // #enddocregion filter-and-sort-usage
  }

  Future<void> withReferences() async {
    // #docregion with-references-summary
    final categoriesWithRefs =
        await db.managers.todoCategory.withReferences().get();

    for (final (category, refs) in categoriesWithRefs) {
      // `refs` has getters for each referenced table
      final todos = await refs.todoItemsRefs.get();
      final user = await refs.user?.getSingle();
    }
    // #enddocregion with-references-summary

    // #docregion with-references-explained
    for (final (category, refs)
        in await db.managers.todoCategory.withReferences().get()) {
      // `refs` contains a getter for each referenced table

      // For example:
      // This is a query builder for all todo items in this category
      refs.todoItemsRefs.get();

      // The above line is equivalent to
      db.managers.todoItems
          .filter((f) => f.category.id.equals(category.id))
          .get();
    }
    // #enddocregion with-references-explained
  }

  Future<void> filterTodoItems() async {
    // #docregion manager_filter
    // All items with a title of "Title"
    db.managers.todoItems.filter((f) => f.title("Title"));

    // All items with a title of "Title" and content of "Content"
    db.managers.todoItems
        .filter((f) => f.title("Title") & f.content("Content"));

    // All items with a title of "Title" or content that is not null
    db.managers.todoItems
        .filter((f) => f.title("Title") | f.content.not.isNull());
    // #enddocregion manager_filter
    // #docregion manager_filter_multiple
    db.managers.todoItems
        .filter((f) => f.title("Title"))
        .filter((f) => f.content("Content"));
    // Is equivalent to
    db.managers.todoItems
        .filter((f) => f.title("Title") & f.content("Content"));
    // #enddocregion manager_filter_multiple
  }

  Future<void> filterWithType() async {
    // #docregion manager_type_specific_filter
    // Filter all items created since 7 days ago
    db.managers.todoItems.filter(
      (f) => f.createdAt.isAfter(DateTime.now().subtract(Duration(days: 7))),
    );

    // Filter all items with a title that starts with "Title"
    db.managers.todoItems.filter((f) => f.title.startsWith('Title'));
// #enddocregion manager_type_specific_filter
  }

  Future<void> orderWithType() async {
// #docregion manager_ordering
    // Order all items by their creation date in ascending order
    db.managers.todoItems.orderBy((o) => o.createdAt.asc());
    // #enddocregion manager_ordering
    // #docregion manager_ordering_multiple
    // Order all items by their title in and then by their content
    db.managers.todoItems.orderBy((o) => o.title.asc() & o.content.asc());
    // is equivalent to
    db.managers.todoItems
        .orderBy((o) => o.title.asc())
        .orderBy((o) => o.content.asc());
    // #enddocregion manager_ordering_multiple

// #docregion manager_ordering_relations
    // Order all items by their category description in ascending order
    db.managers.todoItems.orderBy((o) => o.category.description.asc());
// #enddocregion manager_ordering_relations
  }

  Future<void> count() async {
// #docregion manager_count
    // Count all items
    await db.managers.todoItems.get();

    // Count all items with a title of "Title"
    await db.managers.todoItems.filter((f) => f.title("Title")).count();
// #enddocregion manager_count
  }

  Future<void> exists() async {
// #docregion manager_exists
    // Check if any items exist
    await db.managers.todoItems.exists();

    // Check if any items with a title of "Title" exist
    await db.managers.todoItems.filter((f) => f.title("Title")).exists();
// #enddocregion manager_exists
  }

  Future<void> relationalExample() async {
// #docregion example-references
    // Get all categories with their associated todo items
    final categoryWithRefs =
        await db.managers.todoCategory.withReferences().get();
    for (var (category, ref) in categoryWithRefs) {
      final todos = await ref.todoItemsRefs.get();
    }

    // Get all items with a category description of "School"
    db.managers.todoItems.filter((f) => f.category.description("School"));

    // Retrieve all items ordered by their category description and then by their title
    db.managers.todoItems
        .orderBy((f) => f.category.description.asc() & f.title.asc());
// #enddocregion example-references
  }

  Future<void> relationalFilter() async {
// #docregion manager_filter_forward_references
    // Get all items with a category description of "School"
    db.managers.todoItems.filter((f) => f.category.description("School"));
// #enddocregion manager_filter_forward_references
  }

  Future<void> reverseRelationalFilter() async {
// #docregion manager_filter_back_references
    // Get all categories with a todo item that has a title containing "Trash"
    db.managers.todoCategory.filter(
      (f) => f.todoItemsRefs(
        (f) => f.title.contains("Trash"),
      ),
    );
// #enddocregion manager_filter_back_references
  }

// #docregion manager_references
  Future<void> references() async {
    /// Get each todo, along with a its categories
    final todosWithRefs = await db.managers.todoItems.withReferences().get();
    for (final (todo, refs) in todosWithRefs) {
      final category = await refs.category?.getSingle();
    }

    /// This also works in the reverse
    final categoriesWithRefs =
        await db.managers.todoCategory.withReferences().get();
    for (final (category, refs) in categoriesWithRefs) {
      final todos = await refs.todoItemsRefs.get();
    }
  }

// #enddocregion manager_references
  Future<void> referencesPrefetch() async {
// #docregion manager_prefetch_references
    final todosWithRefs = await db.managers.todoCategory
        .withReferences((prefetch) => prefetch(todoItemsRefs: true))
        .get();
    for (final (category, refs) in todosWithRefs) {
      final todos = refs.todoItemsRefs.prefetchedData;
    }
// #enddocregion manager_prefetch_references
  }

  Future<void> referencesPrefetchStream() async {
// #docregion manager_prefetch_references_stream
    /// Get each todo, along with a its categories
    db.managers.todoCategory
        .withReferences((prefetch) => prefetch(todoItemsRefs: true, user: true))
        .watch()
        .listen(
      (catWithRefs) {
        for (final (cat, refs) in catWithRefs) {
          // Updates to the user table will trigger a query
          final users = refs.user?.prefetchedData;

          // However, updates to the TodoItems table will not trigger a query
          final todos = refs.todoItemsRefs.prefetchedData;
        }
      },
    );
// #enddocregion manager_prefetch_references_stream
  }

  // #docregion addCategoryWithTodos
  Future<void> addCategoryWithTodos(
      TodoCategoryCompanion category, List<TodoItem> todos) {
    return db.transaction(() async {
      final categoryId = await db.managers.todoCategory.create((_) => category);

      // The above category will be remove if this fails
      await db.managers.todoItems.bulkCreate(
          (_) => todos.map((t) => t.copyWith(category: Value(categoryId))));
    });
  }
// #enddocregion addCategoryWithTodos

  void badTransaction(TodoCategoryCompanion category, List<TodoItem> todos) {
    // #docregion streamTransaction
    // This update will be executed after the transaction has been committed
    db.managers.todoCategory.watch().listen(
      (event) {
        print("There are ${event.length} categories");
      },
    );

    // #docregion badTransaction
    db.transaction(() async {
      // All of these operations will run after the transaction has been committed
      db.managers.todoCategory.create((_) => category);

      Future.delayed(Duration(seconds: 1), () {
        db.managers.todoCategory.create((_) => category);
      });

      Timer.periodic(Duration(seconds: 1), (timer) async {
        await db.managers.todoCategory.create((_) => category);
      });
    });
// #enddocregion badTransaction
// #enddocregion streamTransaction
  }

  Future<void> nestedTransaction() async {
    // #docregion nested
    await db.transaction(() async {
      await db.managers.todoCategory
          .create((create) => create(description: 'first'));

      // this is a nested transaction:
      await db.transaction(() async {
        // At this point, the first category is visible
        await db.managers.todoCategory
            .create((create) => create(description: 'second'));
        // Here, the second category is only visible inside this nested
        // transaction.
      });

      // At this point, the second category is visible here as well.

      try {
        await db.transaction(() async {
          // At this point, both categories are visible
          await db.managers.todoCategory
              .create((create) => create(description: 'third'));
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
    // #enddocregion nested
  }

  Future<void> computeWithDatabase() async {
    // #docregion computeWithDatabase
    final todos = await db.computeWithDatabase(
      connect: (connection) => AppDatabase(connection),
      computation: (db) {
        // This opperation won't block the main isolate
        db.managers.todoItems.get();
      },
    );
    // #enddocregion computeWithDatabase
  }
}

// #docregion manager_filter_extensions
// Extend drifts built-in filters by combining the existing filters to create a new one
// or by creating a new filter from scratch
extension After2000Filter on ColumnFilters<DateTime> {
  // Create a new filter by combining existing filters
  ComposableFilter after2000orBefore1900() =>
      isAfter(DateTime(2000)) | isBefore(DateTime(1900));

  // Create a new filter from scratch using the `column` property
  ComposableFilter filterOnUnixEpoch(int value) =>
      $composableFilter(column.unixepoch.equals(value));
}

Future<void> filterWithExtension(AppDatabase db) async {
  // Use the custom filters on any column that is of type DateTime
  db.managers.todoItems.filter((f) => f.createdAt.after2000orBefore1900());

  // Use the custom filter on the `unixepoch` column
  db.managers.todoItems.filter((f) => f.createdAt.filterOnUnixEpoch(0));
}
// #enddocregion manager_filter_extensions

// #docregion manager_ordering_extensions
// Extend drifts built-in orderings by create a new ordering from scratch
extension After2000Ordering on ColumnOrderings<DateTime> {
  ComposableOrdering byUnixEpoch() => ColumnOrderings(column.unixepoch).asc();
}

Future<void> orderingWithExtension(AppDatabase db) async {
  // Use the custom orderings on any column that is of type DateTime
  db.managers.todoItems.orderBy((f) => f.createdAt.byUnixEpoch());
}
// #enddocregion manager_ordering_extensions

// #docregion manager_custom_filter
// Extend the generated table filter composer to add a custom filter
extension NoContentOrBefore2000FilterX on $$TodoItemsTableFilterComposer {
  ComposableFilter noContentOrBefore2000() =>
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

