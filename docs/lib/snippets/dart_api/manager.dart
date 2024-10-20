// ignore_for_file: invalid_use_of_internal_member, unused_local_variable, unused_element, avoid_single_cascade_in_expression_statements

import 'package:drift/drift.dart';

part 'manager.g.dart';

class TodoItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 6, max: 32)();
  TextColumn get content => text().named('body')();
  IntColumn get category =>
      integer().nullable().references(TodoCategory, #id)();
  DateTimeColumn get createdAt => dateTime().nullable()();
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

class Groups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  @ReferenceName("administeredGroups")
  IntColumn get admin => integer().nullable().references(Users, #id)();
  @ReferenceName("ownedGroups")
  IntColumn get owner => integer().references(Users, #id)();
}

// #enddocregion user_group_tables

@DriftDatabase(tables: [TodoItems, TodoCategory, Groups, Users])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);
  @override
  int get schemaVersion => 1;
}

extension ManagerExamples on AppDatabase {
  // #docregion manager_create
  Future<void> createTodoItem() async {
    // Create a new item
    await managers.todoItems
        .create((o) => o(title: 'Title', content: 'Content'));

    // We can also use `mode` and `onConflict` parameters, just
    // like in the `[InsertStatement.insert]` method on the table
    await managers.todoItems.create(
        (o) => o(title: 'Title', content: 'New Content'),
        mode: InsertMode.replace);

    // We can also create multiple items at once
    await managers.todoItems.bulkCreate(
      (o) => [
        o(title: 'Title 1', content: 'Content 1'),
        o(title: 'Title 2', content: 'Content 2'),
      ],
    );
  }
  // #enddocregion manager_create

  // #docregion manager_update
  Future<void> updateTodoItems() async {
    // Update all items
    await managers.todoItems.update((o) => o(content: Value('New Content')));

    // Update multiple items
    await managers.todoItems
        .filter((f) => f.id.isIn([1, 2, 3]))
        .update((o) => o(content: Value('New Content')));
  }
  // #enddocregion manager_update

  // #docregion manager_replace
  Future<void> replaceTodoItems() async {
    // Replace a single item
    var obj = await managers.todoItems.filter((o) => o.id(1)).getSingle();
    obj = obj.copyWith(content: 'New Content');
    await managers.todoItems.replace(obj);

    // Replace multiple items
    var objs =
        await managers.todoItems.filter((o) => o.id.isIn([1, 2, 3])).get();
    objs = objs.map((o) => o.copyWith(content: 'New Content')).toList();
    await managers.todoItems.bulkReplace(objs);
  }
  // #enddocregion manager_replace

  // #docregion manager_delete
  Future<void> deleteTodoItems() async {
    // Delete all items
    await managers.todoItems.delete();

    // Delete a single item
    await managers.todoItems.filter((f) => f.id(5)).delete();
  }
  // #enddocregion manager_delete

// #docregion manager_ordering
  Future<void> orderWithType() async {
    // Order all items by their creation date in ascending order
    managers.todoItems.orderBy((o) => o.createdAt.asc());

    // Order all items by their title in ascending order and then by their content in ascending order
    managers.todoItems.orderBy((o) => o.title.asc() & o.content.asc());
  }
// #enddocregion manager_ordering

// #docregion manager_count
  Future<void> count() async {
    // Count all items
    await managers.todoItems.count();

    // Count all items with a title of "Title"
    await managers.todoItems.filter((f) => f.title("Title")).count();
  }
// #enddocregion manager_count

// #docregion manager_exists
  Future<void> exists() async {
    // Check if any items exist
    await managers.todoItems.exists();

    // Check if any items with a title of "Title" exist
    await managers.todoItems.filter((f) => f.title("Title")).exists();
  }
// #enddocregion manager_exists

// #docregion manager_filter_forward_references
  Future<void> relationalFilter() async {
    // Get all items with a category description of "School"
    managers.todoItems.filter((f) => f.category.description("School"));

    // These can be combined with other filters
    // For example, get all items with a title of "Title" or a category description of "School"
    await managers.todoItems
        .filter(
          (f) => f.title("Title") | f.category.description("School"),
        )
        .exists();
  }
// #enddocregion manager_filter_forward_references

// #docregion manager_filter_back_references
  Future<void> reverseRelationalFilter() async {
    // Get the category that has a todo item with an id of 1
    managers.todoCategory.filter((f) => f.todoItemsRefs((f) => f.id(1)));

    // These can be combined with other filters
    // For example, get all categories with a description of "School" or a todo item with an id of 1
    managers.todoCategory.filter(
      (f) => f.description("School") | f.todoItemsRefs((f) => f.id(1)),
    );
  }
// #enddocregion manager_filter_back_references

// #docregion manager_filter_custom_back_references
  Future<void> reverseNamedRelationalFilter() async {
    // Get all users who are administrators of a group with a name containing "Business"
    // or who own a group with an id of 1, 2, 4, or 5
    managers.users.filter(
      (f) =>
          f.administeredGroups((f) => f.name.contains("Business")) |
          f.ownedGroups((f) => f.id.isIn([1, 2, 4, 5])),
    );
  }
// #enddocregion manager_filter_custom_back_references

// #docregion manager_prefetch_references
  Future<void> referencesPrefetch() async {
    /// Get each todo, along with a its categories
    final categoriesWithReferences = await managers.todoItems
        .withReferences(
          (prefetch) => prefetch(category: true),
        )
        .get();
    for (final (todo, refs) in categoriesWithReferences) {
      final category = refs.category?.prefetchedData?.firstOrNull;
      // No longer needed
      // final category = await refs.category?.getSingle();
    }

    /// This also works in the reverse
    final todosWithRefs = await managers.todoCategory
        .withReferences((prefetch) => prefetch(todoItemsRefs: true))
        .get();
    for (final (category, refs) in todosWithRefs) {
      final todos = refs.todoItemsRefs.prefetchedData;
      // No longer needed
      //final todos = await refs.todoItemsRefs.get();
    }
  }
// #enddocregion manager_prefetch_references

  Future<void> referencesPrefetchStream() async {
// #docregion manager_prefetch_references_stream
    /// Get each todo, along with a its categories
    managers.todoCategory
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
}

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
      .computedField((o) => o.todoItemsRefs((o) => o.id).count());

  /// Create a copy of the manager with the computed fields you want to use
  final manager = db.managers.todoCategory.withFields([todoCountcomputedField]);

  /// Read the result of the computed field
  for (final (category, refs) in await manager.get()) {
    final todoCount = todoCountcomputedField.read(refs);
    print('Category ${category.id} has $todoCount todos');
  }
  // #enddocregion aggregated_annotations
}

Future<void> selectTodoItems(AppDatabase db) async {
  // #docregion manager_select
  await db.managers.todoItems.get();
  // #enddocregion manager_select
  // #docregion core_select
  await db.select(db.todoItems).get();
  // #enddocregion core_select

  // #docregion manager_watch
  db.managers.todoItems.watch();

  // #enddocregion manager_watch
  // #docregion core_watch
  db.select(db.todoItems).watch();
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
  // All items with a title of "Title"
  db.managers.todoItems.filter((f) => f.title("Title"));
  // #enddocregion manager_filter

  // #docregion core_filter
  // All items with a title of "Title"
  db.select(db.todoItems)..where((tbl) => tbl.title.equals("Title"));
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

Future<void> filterTodoItemsRefs(AppDatabase db) async {
  // #docregion manager_filter_references
  // All items with a category description of "School"
  db.managers.todoItems.filter((f) => f.category.description("School"));
  // #enddocregion manager_filter_references

  // #docregion core_filter_references
  // All items with a title of "Title"
  db.select(db.todoItems).join([
    leftOuterJoin(
        db.todoCategory, db.todoCategory.id.equalsExp(db.todoItems.category),
        useColumns: false)
  ]).where(db.todoCategory.description.equals("School"));
  // #enddocregion core_filter_references

  // #docregion manager_references
  for (final (todo, refs)
      in await db.managers.todoItems.withReferences().get()) {
    final category = await refs.category?.getSingle();
    print(
        'Todo ${todo.id} has a category with the description ${category?.description}');
  }
  // #enddocregion manager_references
  // #docregion manager_references_prefetch
  for (final (todo, refs) in await db.managers.todoItems
      .withReferences((prefetch) => prefetch(category: true))
      .get()) {
    final category = refs.category?.prefetchedData?.firstOrNull;
    print(
        'Todo ${todo.id} has a category with the description ${category?.description}');
  }
  // #enddocregion manager_references_prefetch

  // #docregion core_references
  // Build a select statement with a left outer join to fetch the referenced data
  final query = db.select(db.todoItems).join([
    leftOuterJoin(
        db.todoCategory, db.todoCategory.id.equalsExp(db.todoItems.category))
  ])
    ..where(db.todoCategory.description.equals("School"));

  // Map the results to a list of tuples containing the todo and category
  final results = await query
      .asyncMap((p0) =>
          (p0.readTable(db.todoItems), p0.readTableOrNull(db.todoCategory)))
      .get();

  // Print the results
  for (final (todo, category) in results) {
    print(
        'Todo ${todo.id} has a category with the description ${category?.description}');
  }
  // #enddocregion core_references
}
