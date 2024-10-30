// ignore_for_file: unused_element

import 'package:drift/drift.dart';

part 'dataclass.g.dart';

// #docregion table
class Users extends Table {
  late final id = integer().autoIncrement()();
  late final username = text()();
}
// #enddocregion table

// #docregion data-class-name
@DataClassName('Category')
class Categories extends Table {
  late final id = integer().autoIncrement()();
  late final title = text()();
}
// #enddocregion data-class-name

// #docregion default-json-keys
class Todos extends Table {
  late final id = integer().autoIncrement()();
  late final title = text()();
  late final createdAt = dateTime().withDefault(currentDateAndTime)();
}
// #enddocregion default-json-keys

class Todos1 extends Table {
  // #docregion custom-json-keys
  @JsonKey('created')
  late final createdAt = dateTime().withDefault(currentDateAndTime)();
  // #enddocregion custom-json-keys
}

@DriftDatabase(tables: [Users, Categories])
class Database extends _$Database {
  Database(super.e);

  @override
  int get schemaVersion => 1;
}

void _queryManager(Database db) async {
  // #docregion simple-inserts-manager
  await db.managers.users.create((row) => row(username: 'firstuser'));
  // #enddocregion simple-inserts-manager

  // #docregion simple-select-manager
  final User firstUser = await db.managers.users.limit(1).getSingle();
  print("Hello ${firstUser.username}!");
  // #enddocregion simple-select-manager

  // #docregion generated-dataclass
  // Read a single user from the database.
  final User user = await db.managers.users.filter((f) => f.id(1)).getSingle();

  /// Interact with the user in a type-safe manner.
  print("Hello ${user.username}!");
  // #enddocregion generated-dataclass

  // #docregion generated-value
  await db.users.insertOne(UsersCompanion(
    id: Value.absent(), // (1)!
    username: Value('user'), // (2)!
  ));

  await (db.update(db.users)..where((tbl) => tbl.id.equals(1)))
      .write(UsersCompanion(username: Value("New user")));
  // #enddocregion generated-value
}

void _queryCore(Database db) async {
  // #docregion simple-inserts-core
  await db.users.insertOne(UsersCompanion.insert(username: 'firstuser'));
  // #enddocregion simple-inserts-core

  // #docregion simple-select-core
  final User firstUser = await (db.users.select()..limit(1)).getSingle();
  print("Hello ${firstUser.username}!");
  // #enddocregion simple-select-core
}

// #docregion data-class-name

void readCategories(Database db) async {
  // Thanks to @DataClassName, the generated class is `Category` instead of
  // `Categorie`.
  final List<Category> categories = await db.categories.all().get();
  print('Current categories: $categories');
}
// #enddocregion data-class-name

void _fromAndToJson() {
  // #docregion from-json
  final User user = User.fromJson({'id': 3, 'username': 'awesomeuser'});
  print('Deserialized user: ${user.username}');
  // #enddocregion from-json
}
