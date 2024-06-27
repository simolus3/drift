// ignore_for_file: invalid_use_of_internal_member, unused_local_variable

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
  Future<void> createTodoItem() async {
    // #docregion manager_create
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
    // #enddocregion manager_create
  }

  Future<void> updateTodoItems() async {
    // #docregion manager_update
    // Update all items
    await managers.todoItems.update((o) => o(content: Value('New Content')));

    // Update multiple items
    await managers.todoItems
        .filter((f) => f.id.isIn([1, 2, 3]))
        .update((o) => o(content: Value('New Content')));
    // #enddocregion manager_update
  }

  Future<void> replaceTodoItems() async {
    // #docregion manager_replace
    // Replace a single item
    var obj = await managers.todoItems.filter((o) => o.id(1)).getSingle();
    obj = obj.copyWith(content: 'New Content');
    await managers.todoItems.replace(obj);

    // Replace multiple items
    var objs =
        await managers.todoItems.filter((o) => o.id.isIn([1, 2, 3])).get();
    objs = objs.map((o) => o.copyWith(content: 'New Content')).toList();
    await managers.todoItems.bulkReplace(objs);
    // #enddocregion manager_replace
  }

  Future<void> deleteTodoItems() async {
    // #docregion manager_delete
    // Delete all items
    await managers.todoItems.delete();

    // Delete a single item
    await managers.todoItems.filter((f) => f.id(5)).delete();
    // #enddocregion manager_delete
  }

  Future<void> selectTodoItems() async {
    // #docregion manager_select
    // Get all items
    managers.todoItems.get();

    // A stream of all the todo items, updated in real-time
    managers.todoItems.watch();

    // To get a single item, apply a filter and call `getSingle`
    await managers.todoItems.filter((f) => f.id(1)).getSingle();
    // #enddocregion manager_select
  }

  Future<void> filterTodoItems() async {
    // #docregion manager_filter
    // All items with a title of "Title"
    managers.todoItems.filter((f) => f.title("Title"));

    // All items with a title of "Title" and content of "Content"
    managers.todoItems.filter((f) => f.title("Title") & f.content("Content"));

    // All items with a title of "Title" or content that is not null
    managers.todoItems.filter((f) => f.title("Title") | f.content.not.isNull());
    // #enddocregion manager_filter
  }

  Future filterWithType() async {
    // #docregion manager_type_specific_filter
    // Filter all items created since 7 days ago
    managers.todoItems.filter(
        (f) => f.createdAt.isAfter(DateTime.now().subtract(Duration(days: 7))));

    // Filter all items with a title that starts with "Title"
    managers.todoItems.filter((f) => f.title.startsWith('Title'));
// #enddocregion manager_type_specific_filter
  }

  Future orderWithType() async {
// #docregion manager_ordering
    // Order all items by their creation date in ascending order
    managers.todoItems.orderBy((o) => o.createdAt.asc());

    // Order all items by their title in ascending order and then by their content in ascending order
    managers.todoItems.orderBy((o) => o.title.asc() & o.content.asc());
// #enddocregion manager_ordering
  }

  Future count() async {
// #docregion manager_count
    // Count all items
    await managers.todoItems.count();

    // Count all items with a title of "Title"
    await managers.todoItems.filter((f) => f.title("Title")).count();
// #enddocregion manager_count
  }

  Future exists() async {
// #docregion manager_exists
    // Check if any items exist
    await managers.todoItems.exists();

    // Check if any items with a title of "Title" exist
    await managers.todoItems.filter((f) => f.title("Title")).exists();
// #enddocregion manager_exists
  }

  Future relationalFilter() async {
// #docregion manager_filter_forward_references
    // Get all items with a category description of "School"
    managers.todoItems.filter((f) => f.category.description("School"));

    // These can be combined with other filters
    // For example, get all items with a title of "Title" or a category description of "School"
    await managers.todoItems
        .filter(
          (f) => f.title("Title") | f.category.description("School"),
        )
        .exists();
// #enddocregion manager_filter_forward_references
  }

  Future reverseRelationalFilter() async {
// #docregion manager_filter_back_references
    // Get the category that has a todo item with an id of 1
    managers.todoCategory.filter((f) => f.todoItemsRefs((f) => f.id(1)));

    // These can be combined with other filters
    // For example, get all categories with a description of "School" or a todo item with an id of 1
    managers.todoCategory.filter(
      (f) => f.description("School") | f.todoItemsRefs((f) => f.id(1)),
    );
// #enddocregion manager_filter_back_references
  }

  Future reverseNamedRelationalFilter() async {
// #docregion manager_filter_custom_back_references
    // Get all users who are administrators of a group with a name containing "Business"
    // or who own a group with an id of 1, 2, 4, or 5
    managers.users.filter(
      (f) =>
          f.administeredGroups((f) => f.name.contains("Business")) |
          f.ownedGroups((f) => f.id.isIn([1, 2, 4, 5])),
    );
// #enddocregion manager_filter_custom_back_references
  }

  Future managerWithRefs() async {
// #docregion manager_with_refs
    final todoWithCategory = await managers.todoItems
        .filter((f) => f.id(1))
        .withReferences()
        .getSingle();
    final category = await todoWithCategory.category?.getSingle();

    // You could also do nested references, even with a filter
    // Here we will get the category of this todo item, with all the todo items in that category
    final categoryWithTodos =
        await todoWithCategory.category?.withReferences().getSingle();
    // And now we can get all the todo items in that category
    final allTodoInCategory = await categoryWithTodos?.todoItemsRefs.get();
    // We could even filter it, so here is all the todo items in that category with a title of "Title"
    final allTodoInCategoryWithTitle = await categoryWithTodos?.todoItemsRefs
        .filter((f) => f.title("Title"))
        .get();
// #enddocregion manager_with_refs
  }

  Future managerWithRefsNPlus1() async {
// #docregion manager_with_refs_n_plus_1
    // Get all users with their referenced groups
    final usersWithReferences = await managers.users.withReferences().get();
    for (var i in usersWithReferences) {
      final user = i.user;
      final administeredGroups =
          await i.administeredGroups.get(); // Will run many queries
    }
// #enddocregion manager_with_refs_n_plus_1
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

Future filterWithExtension(AppDatabase db) async {
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

Future orderingWithExtension(AppDatabase db) async {
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

Future customFilter(AppDatabase db) async {
  // Use the custom filter on the `TodoItems` table
  db.managers.todoItems.filter((f) => f.noContentOrBefore2000());
}
// #enddocregion manager_custom_filter

// #docregion manager_custom_ordering
// Extend the generated table filter composer to add a custom filter
extension ContentThenCreationDataX on $$TodoItemsTableOrderingComposer {
  ComposableOrdering contentThenCreatedAt() => content.asc() & createdAt.asc();
}

Future customOrdering(AppDatabase db) async {
  // Use the custom ordering on the `TodoItems` table
  db.managers.todoItems.orderBy((f) => f.contentThenCreatedAt());
}
// #enddocregion manager_custom_ordering
