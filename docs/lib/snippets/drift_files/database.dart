// #docregion overview
import 'package:drift/drift.dart';

part 'database.g.dart';

@DriftDatabase(
  include: {'tables.drift'},
)
class MyDb extends _$MyDb {
  MyDb(super.e);

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
