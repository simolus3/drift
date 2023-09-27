import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:drift/web.dart';
import 'package:sqlite3/wasm.dart';

typedef _$MyWebDatabase = GeneratedDatabase;

// #docregion connect
DatabaseConnection connectOnWeb() {
  return DatabaseConnection.delayed(Future(() async {
    final result = await WasmDatabase.open(
      databaseName: 'my_app_db', // prefer to only use valid identifiers here
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.dart.js'),
    );

    if (result.missingFeatures.isNotEmpty) {
      // Depending how central local persistence is to your app, you may want
      // to show a warning to the user if only unrealiable implemetentations
      // are available.
      print('Using ${result.chosenImplementation} due to missing browser '
          'features: ${result.missingFeatures}');
    }

    return result.resolvedExecutor;
  }));
}

// You can then use this method to open your database:
class MyWebDatabase extends _$MyWebDatabase {
  MyWebDatabase._(QueryExecutor e) : super(e);

  factory MyWebDatabase() => MyWebDatabase._(connectOnWeb());
  // ...
  // #enddocregion connect

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables =>
      throw UnimplementedError();

  @override
  int get schemaVersion => throw UnimplementedError();
// #docregion connect
}
// #enddocregion connect

// #docregion migrate-wasm
// If you've previously opened your database like this
Future<WasmDatabase> customDatabase() async {
  final sqlite3 = await WasmSqlite3.loadFromUrl(Uri.parse('/sqlite3.wasm'));
  final fs = await IndexedDbFileSystem.open(dbName: 'my_app');
  sqlite3.registerVirtualFileSystem(fs, makeDefault: true);

  return WasmDatabase(
    sqlite3: sqlite3,
    path: '/app.db',
  );
}
// #enddocregion migrate-wasm

DatabaseConnection migrateAndConnect() {
  return DatabaseConnection.delayed(Future(() async {
    // #docregion migrate-wasm
    // Then you can migrate like this
    final result = await WasmDatabase.open(
      databaseName: 'my_app',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.dart.js'),
      initializeDatabase: () async {
        // Manually open the file system previously used
        final fs = await IndexedDbFileSystem.open(dbName: 'my_app');
        const oldPath = '/app.db'; // The path passed to WasmDatabase before

        Uint8List? oldDatabase;

        // Check if the old database exists
        if (fs.xAccess(oldPath, 0) != 0) {
          // It does, then copy the old file
          final (file: file, outFlags: _) =
              fs.xOpen(Sqlite3Filename(oldPath), 0);
          final blob = Uint8List(file.xFileSize());
          file.xRead(blob, 0);
          file.xClose();
          fs.xDelete(oldPath, 0);

          oldDatabase = blob;
        }

        await fs.close();
        return oldDatabase;
      },
    );
    // #enddocregion migrate-wasm

    return result.resolvedExecutor;
  }));
}

DatabaseConnection migrateFromLegacy() {
  return DatabaseConnection.delayed(Future(() async {
    // #docregion migrate-legacy
    final result = await WasmDatabase.open(
      databaseName: 'my_app',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.dart.js'),
      initializeDatabase: () async {
        final storage = await DriftWebStorage.indexedDbIfSupported('old_db');
        await storage.open();

        final blob = await storage.restore();
        await storage.close();

        return blob;
      },
    );
    // #enddocregion migrate-legacy

    return result.resolvedExecutor;
  }));
}

// #docregion setupAll
void setupDatabase(CommonDatabase database) {
  database.createFunction(
    functionName: 'my_function',
    function: (args) => args.length,
  );
}

void main() {
  WasmDatabase.workerMainForOpen(
    setupAllDatabases: setupDatabase,
  );
}
// #enddocregion setupAll

void withSetup() async {
  // #docregion setupLocal
  final result = await WasmDatabase.open(
    databaseName: 'my_app_db', // prefer to only use valid identifiers here
    sqlite3Uri: Uri.parse('sqlite3.wasm'),
    driftWorkerUri: Uri.parse('my_drift_worker.dart.js'),
    localSetup: setupDatabase,
  );
  // #enddocregion setupLocal
  print(result);
}
