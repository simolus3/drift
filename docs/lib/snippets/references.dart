// ignore_for_file: unused_local_variable, unused_element

import 'package:drift/drift.dart';

import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';
part 'references.g.dart';

// #docregion user_group_schema
class Group extends Table {
  late final id = integer().autoIncrement()();
  late final name = text()();
}

class User extends Table {
  late final id = integer().autoIncrement()();
  late final name = text().unique()();

  @ReferenceName("users") //(1)!
  late final group = integer().references(Group, #id /*(2)!*/)();
}
// #enddocregion user_group_schema

class Author extends Table {
  late final uuid = text().clientDefault(() => Uuid().v4())();
  late final name = text()();

  @override
  Set<Column> get primaryKey => {uuid};
}

// #docregion define_deferred_constraints
class Post extends Table {
  late final id = integer().autoIncrement()();
  late final author =
      text().references(Author, #uuid, initiallyDeferred: true)();
  late final content = text()();
}
// #enddocregion define_deferred_constraints

// #docregion many_to_many_schema
class Books extends Table {
  late final id = integer().autoIncrement()();
  late final title = text()();
}

class Tags extends Table {
  late final id = integer().autoIncrement()();
  late final name = text()();
}

class TagBookRelationship extends Table {
  late final book = integer().references(Books, #id)();
  late final tag = integer().references(Tags, #id)();

  @override
  Set<Column> get primaryKey => {book, tag};
}
// #enddocregion many_to_many_schema

@DriftDatabase(
    tables: [User, Group, Author, Post, Books, Tags, TagBookRelationship])
// #docregion foreign_keys_on
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        await customStatement('pragma foreign_keys = ON;');
      },
    );
  }
}
// #enddocregion foreign_keys_on

class User2 extends Table {
  // #docregion key_action_cascade
  @ReferenceName("users") //(1)!
  late final group =
      integer().references(Group, #id, onDelete: KeyAction.setNull)();
  // #enddocregion key_action_cascade
}

Future<void> main() async {
  // #docregion user_group_schema_usage
  // Initialize the database
  final db = AppDatabase(driftDatabase(name: 'app.db'));

  // Create the teacher and student groups
  final teacherGroup =
      await db.managers.group.createReturning((o) => o(name: "Teachers"));
  final studentGroup =
      await db.managers.group.createReturning((o) => o(name: "Students"));

  // Create some users
  await db.managers.user
      .createReturning((o) => o(name: "Alice", group: teacherGroup.id));
  await db.managers.user
      .createReturning((o) => o(name: "Clark", group: teacherGroup.id));
  await db.managers.user
      .createReturning((o) => o(name: "Bob", group: studentGroup.id));
  await db.managers.user
      .createReturning((o) => o(name: "David", group: studentGroup.id));
  await db.managers.user
      .createReturning((o) => o(name: "Simon", group: studentGroup.id));

  // Query all users in the teacher group
  final teachers =
      await db.managers.user.filter((f) => f.group.id(teacherGroup.id)).get();

  // Get the group which Alice belongs to
  final alicesGroup = await db.managers.group
      .filter((f) => f.users((f) => f.name("Alice")))
      .get();
  // #enddocregion user_group_schema_usage

  // #docregion deferred_constraints
  await db.transaction(() async {
    final authorId = "f7b3b3e0-4b7b-11ec-8d3d-0242ac130003";
    final post = await db.managers.post
        .createReturning((o) => o(author: authorId, content: "Lorem ipsum..."));
    final author = await db.managers.author
        .createReturning((o) => o(name: "Alice", uuid: Value(authorId)));
  });

  // #enddocregion deferred_constraints

  db.transaction(
    () async {
      // #docregion many_to_many_usage
      // Create some books
      final harryPotter = await db.managers.books
          .createReturning((o) => o(title: "Harry Potter"));
      final clifforTheBigRedDog = await db.managers.books
          .createReturning((o) => o(title: "Clifford The Big Red Dog"));

      // Create some tags
      final magic =
          await db.managers.tags.createReturning((o) => o(name: "Magic"));
      final scienceFiction = await db.managers.tags
          .createReturning((o) => o(name: "Science Fiction"));
      final kids =
          await db.managers.tags.createReturning((o) => o(name: "Kids"));
      final friendship =
          await db.managers.tags.createReturning((o) => o(name: "Friendship"));

      // Assign tags to the book
      await db.managers.tagBookRelationship.bulkCreate((o) => [
            o(book: harryPotter.id, tag: magic.id),
            o(book: harryPotter.id, tag: scienceFiction.id),
            o(book: harryPotter.id, tag: friendship.id),
            o(book: clifforTheBigRedDog.id, tag: kids.id),
            o(book: clifforTheBigRedDog.id, tag: friendship.id),
          ]);

      // Query all books with the tag "Magic"
      final magicBooks = await db.managers.tagBookRelationship
          .filter((f) => f.tag.id(magic.id))
          .withReferences((prefetch) => prefetch(book: true, tag: true))
          .get();

      // Print the title of the books and the tag name
      for (final (_, refs) in magicBooks) {
        final book = refs.book!.prefetchedData!.single;
        final tag = refs.tag!.prefetchedData!.single;
        print("${book.title} is tagged as ${tag.name}");
      }
      // #enddocregion many_to_many_usage
    },
  );
}

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
class Database extends _$Database {
  Database(super.e);
  @override
  int get schemaVersion => 1;
}

extension ManagerExamples on Database {
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

  Future<void> relationalOrder() async {
    // #docregion manager_order_forward_references
    // First order by category description, then by title
    managers.todoItems.orderBy(
      (f) => f.category.description.asc() & f.title.asc(),
    );
    // #enddocregion manager_order_forward_references
  }

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

  Future<void> references() async {
    // #docregion manager_references
    /// Get each todo, along with a its categories
    final todosWithRefs = await managers.todoItems.withReferences().get();
    for (final (todo, refs) in todosWithRefs) {
      final category = await refs.category?.getSingle();
    }

    /// This also works in the reverse
    final categoriesWithRefs =
        await managers.todoCategory.withReferences().get();
    for (final (category, refs) in categoriesWithRefs) {
      final todos = await refs.todoItemsRefs.get();
    }
    // #enddocregion manager_references
  }

  Future<void> referencesPrefetch() async {
    // #docregion manager_prefetch_references
    /// Get each todo, along with a its categories
    final categoriesWithReferences = await managers.todoItems
        .withReferences(
          (prefetch) => prefetch(category: true),
        )
        .get();
    for (final (todo, refs) in categoriesWithReferences) {
      final category = refs.category?.prefetchedData?.firstOrNull;
    }

    /// This also works in the reverse
    final todosWithRefs = await managers.todoCategory
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
