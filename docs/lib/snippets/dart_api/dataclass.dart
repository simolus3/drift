import 'dart:convert';

import 'package:drift/drift.dart';

part 'dataclass.g.dart';

// #docregion table
class Users extends Table {
  late final id = integer().autoIncrement()();
  late final name = text()();
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

void _query(Database db) async {
  // #docregion generated-dataclass
  // Read a single user from the database.
  final User user = await db.managers.users.filter((f) => f.id(1)).getSingle();

  /// Interact with the user in a type-safe manner.
  print("Hello ${user.name}!");
  // #enddocregion generated-dataclass

  // #docregion generated-companion
  // Create a new user with the Manager API
  await db.managers.users.create((o) => o(name: "New user") /* (1)! */);

  // Update the user with the Manager API
  await db.managers.users
      .filter((f) => f.id(1))
      .update((o) => o(name: Value("New user")) /* (1)! */);

  // Create a new user with the Core API
  db.into(db.users).insert(UsersCompanion.insert(name: "New user"));

  // Update the user with the Core API
  await (db.update(db.users)..where((tbl) => tbl.id.equals(1)))
      .write(UsersCompanion(name: Value("New user")));
  // #enddocregion generated-companion

  // #docregion generated-value
  await (db.update(db.users)..where((tbl) => tbl.id.equals(1)))
      .write(UsersCompanion(name: Value("New user")));
  // #enddocregion generated-value
}
