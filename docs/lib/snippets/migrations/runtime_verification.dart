import 'package:drift/drift.dart';

// #docregion native
// import the migrations tooling
import 'package:drift_dev/api/migrations_native.dart';
// #enddocregion native

const kDebugMode = true;

abstract class _$MyDatabase extends GeneratedDatabase {
  _$MyDatabase(super.executor);
}

// #docregion native

class MyDatabase extends _$MyDatabase {
// #enddocregion native
  MyDatabase(super.executor);

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables =>
      throw UnimplementedError();

  @override
  int get schemaVersion => throw UnimplementedError();

  // #docregion native
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {/* ... */},
        onUpgrade: (m, from, to) async {/* your existing migration logic */},
        beforeOpen: (details) async {
          // your existing beforeOpen callback, enable foreign keys, etc.

          if (kDebugMode) {
            // This check pulls in a fair amount of code that's not needed
            // anywhere else, so we recommend only doing it in debug builds.
            await validateDatabaseSchema();
          }
        },
      );
}
// #enddocregion native
