import 'package:drift/drift.dart';

import '../setup/database.dart';

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

  // #docregion manager_select
  Future<void> selectTodoItems() async {
    // Get all items
    managers.todoItems.get();

    // A stream of all the todo items, updated in real-time
    managers.todoItems.watch();

    // To get a single item, apply a filter and call `getSingle`
    await managers.todoItems.filter((f) => f.id(1)).getSingle();
  }
  // #enddocregion manager_select

  // #docregion manager_filter
  Future<void> filterTodoItems() async {
    // All items with a title of "Title"
    managers.todoItems.filter((f) => f.title("Title"));

    // All items with a title of "Title" and content of "Content"
    managers.todoItems.filter((f) => f.title("Title") & f.content("Content"));

    // All items with a title of "Title" or content that is not null
    managers.todoItems.filter((f) => f.title("Title") | f.content.not.isNull());
  }
  // #enddocregion manager_filter

  // #docregion manager_type_specific_filter
  Future filterWithType() async {
    // Filter all items created since 7 days ago
    managers.todoItems.filter(
        (f) => f.createdAt.isAfter(DateTime.now().subtract(Duration(days: 7))));

    // Filter all items with a title that starts with "Title"
    managers.todoItems.filter((f) => f.title.startsWith('Title'));
  }
// #enddocregion manager_type_specific_filter

// #docregion manager_ordering
  Future orderWithType() async {
    // Order all items by their creation date in ascending order
    managers.todoItems.orderBy((o) => o.createdAt.asc());

    // Order all items by their title in ascending order and then by their content in ascending order
    managers.todoItems.orderBy((o) => o.title.asc() & o.content.asc());
  }
// #enddocregion manager_ordering

// #docregion manager_count
  Future count() async {
    // Count all items
    await managers.todoItems.count();

    // Count all items with a title of "Title"
    await managers.todoItems.filter((f) => f.title("Title")).count();
  }
// #enddocregion manager_count

// #docregion manager_exists
  Future exists() async {
    // Check if any items exist
    await managers.todoItems.exists();

    // Check if any items with a title of "Title" exist
    await managers.todoItems.filter((f) => f.title("Title")).exists();
  }
// #enddocregion manager_exists

// #docregion manager_filter_forward_references
  Future relationalFilter() async {
    // Get all items with a category description of "School"
    managers.todoItems
        .filter((f) => f.category((f) => f.description("School")));

    // These can be combined with other filters
    // For example, get all items with a title of "Title" or a category description of "School"
    await managers.todoItems
        .filter(
          (f) => f.title("Title") | f.category((f) => f.description("School")),
        )
        .exists();
  }
// #enddocregion manager_filter_forward_references

// #docregion manager_filter_forward_references
  Future reverseRelationalFilter() async {
    // Get the category that has a todo item with an id of 1
    managers.todoCategory.filter((f) => f.todoItemsRefs((f) => f.id(1)));

    // These can be combined with other filters
    // For example, get all categories with a description of "School" or a todo item with an id of 1
    managers.todoCategory.filter(
      (f) => f.description("School") | f.todoItemsRefs((f) => f.id(1)),
    );
  }
// #enddocregion manager_filter_forward_references
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
      ComposableFilter(column.unixepoch.equals(value), inverted: inverted);
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

// #docregion reference_name_example
class User extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  @ReferenceName("users")
  IntColumn get group => integer().nullable().references(Group, #id)();
}

class Group extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}
// #enddocregion reference_name_example
