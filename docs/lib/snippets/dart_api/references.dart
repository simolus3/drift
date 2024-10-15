// ignore_for_file: unused_local_variable, unused_element

import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:drift_flutter/drift_flutter.dart';

part 'references.g.dart';

// #docregion many-to-one
class Users extends Table {
  late final id = integer().autoIncrement()();
  late final email = text()();
  late final group = integer().references(Groups, #id)();
}

class Groups extends Table {
  late final id = integer().autoIncrement()();
  late final name = text()();
}
// #enddocregion many-to-one

@DriftDatabase(tables: [Users, Groups])
class Database extends _$Database {
  Database(super.e);

  @override
  int get schemaVersion => 1;
}

void _query(Database db) async {
  // #docregion many-to-one-usage
  // Create a Admin group
  final groupId = await db.managers.groups.create((o) => o(name: "Admin"));

  // Create a user in that group
  await db.managers.users
      .create((o) => o(email: "user@domain.com", group: groupId));
  // #enddocregion many-to-one-usage
}
