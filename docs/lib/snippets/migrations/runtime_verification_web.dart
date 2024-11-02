import 'package:drift/drift.dart';

// #docregion web
// import the migrations tooling
import 'package:drift_dev/api/migrations_web.dart';
import 'package:sqlite3/wasm.dart';
// #enddocregion web

const kDebugMode = true;

abstract class _$MyDatabase extends GeneratedDatabase {
  _$MyDatabase(super.executor);
}

// #docregion web

class MyDatabase extends _$MyDatabase {
// #enddocregion web
  MyDatabase(super.executor);

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables =>
      throw UnimplementedError();

  @override
  int get schemaVersion => throw UnimplementedError();

  // #docregion web
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {/* ... */},
        onUpgrade: (m, from, to) async {/* your existing migration logic */},
        beforeOpen: (details) async {
          // your existing beforeOpen callback, enable foreign keys, etc.

          // This check pulls in a fair amount of code that's not needed
          // anywhere else, so we recommend only doing it in debug builds.
          if (kDebugMode) {
            // The web schema verifier needs a sqlite3 instance to open another
            // version of your database so that the two can be compared.
            final sqlite3 = await WasmSqlite3.loadFromUrl(Uri.parse('/'));
            sqlite3.registerVirtualFileSystem(InMemoryFileSystem(),
                makeDefault: true);
            await validateDatabaseSchema(sqlite3: sqlite3);
          }
        },
      );
}
// #enddocregion web
