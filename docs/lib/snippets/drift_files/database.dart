// #docregion overview
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'database.g.dart';

@DriftDatabase(
  include: {'tables.drift'},
)
class MyDb extends _$MyDb {
  // This example creates a simple in-memory database (without actual
  // persistence).
  // To store data, see the database setups from other "Getting started" guides.
  MyDb() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;
}
// #enddocregion overview

extension MoreSnippets on MyDb {
  // #docregion dart_interop_insert
  Future<void> insert(TodosCompanion companion) async {
    await into(todos).insert(companion);
  }
  // #enddocregion dart_interop_insert
}
