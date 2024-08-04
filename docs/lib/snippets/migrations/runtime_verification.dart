import 'package:drift/drift.dart';

// #docregion verify_scheme
// Import the migrations tooling
import 'package:drift_dev/api/migrations.dart';

// #enddocregion verify_scheme

const kDebugMode = true;

abstract class _$MyDatabase extends GeneratedDatabase {
  _$MyDatabase(super.executor);
}

// #docregion verify_scheme
class MyDatabase extends _$MyDatabase {
  //...

// #enddocregion verify_scheme
  MyDatabase(super.executor);

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables =>
      throw UnimplementedError();

  @override
  int get schemaVersion => throw UnimplementedError();

  // #docregion verify_scheme
  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          // ...

          if (kDebugMode) {
            // Only validate schema in debug mode to avoid performance impact and
            // to decrease bundle size. This check helps catch migration
            // issues during development.
            await validateDatabaseSchema();
          }
        },
      );
}
// #enddocregion verify_scheme
