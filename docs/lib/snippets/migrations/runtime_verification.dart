import 'package:drift/drift.dart';

// #docregion
// import the migrations tooling
import 'package:drift_dev/api/migrations.dart';
// #enddocregion

const kDebugBuild = true;

abstract class _$MyDatabase extends GeneratedDatabase {
  _$MyDatabase(SqlTypeSystem types, QueryExecutor executor)
      : super(types, executor);
}

// #docregion

class MyDatabase extends _$MyDatabase {
// #enddocregion
  MyDatabase(SqlTypeSystem types, QueryExecutor executor)
      : super(types, executor);

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables =>
      throw UnimplementedError();

  @override
  int get schemaVersion => throw UnimplementedError();

  // #docregion
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {/* ... */},
        onUpgrade: (m, from, to) async {/* your existing migration logic */},
        beforeOpen: (details) async {
          // your existing beforeOpen callback, enable foreign keys, etc.

          if (kDebugBuild) {
            // This check pulls in a fair amount of code that's not needed
            // anywhere else, so we recommend only doing it in debug builds.
            await validateDatabaseSchema();
          }
        },
      );
}
// #enddocregion
