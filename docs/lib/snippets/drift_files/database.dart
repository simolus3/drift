import 'package:drift/drift.dart';

part 'database.g.dart';

// #docregion sql_simple_schema_db
@DriftDatabase(include: {'tables.drift'})
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
// #enddocregion sql_simple_schema_db

extension MoreSnippets on AppDatabase {
  // #docregion dart_interop_insert
  Future<void> insert(TodosCompanion companion) async {
    await into(todos).insert(companion);
  }
  // #enddocregion dart_interop_insert
}
