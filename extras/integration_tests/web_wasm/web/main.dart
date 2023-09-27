import 'dart:convert';
import 'dart:html';
import 'dart:js_util';

import 'package:async/async.dart';
import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:http/http.dart' as http;
import 'package:web_wasm/initialization_mode.dart';
import 'package:web_wasm/src/database.dart';
import 'package:sqlite3/wasm.dart';

const dbName = 'drift_test';
final sqlite3WasmUri = Uri.parse('sqlite3.wasm');
final driftWorkerUri = Uri.parse('worker.dart.js');

TestDatabase? openedDatabase;
StreamQueue<void>? tableUpdates;

InitializationMode initializationMode = InitializationMode.none;

void main() {
  _addCallbackForWebDriver('detectImplementations', _detectImplementations);
  _addCallbackForWebDriver('open', _open);
  _addCallbackForWebDriver('insert', _insert);
  _addCallbackForWebDriver('get_rows', _getRows);
  _addCallbackForWebDriver('wait_for_update', _waitForUpdate);
  _addCallbackForWebDriver('enable_initialization', (arg) async {
    initializationMode = InitializationMode.values.byName(arg!);
    return true;
  });
  _addCallbackForWebDriver('delete_database', (arg) async {
    final result = await WasmDatabase.probe(
      sqlite3Uri: sqlite3WasmUri,
      driftWorkerUri: driftWorkerUri,
    );

    final decoded = json.decode(arg!);

    await result.deleteDatabase(
      (WebStorageApi.byName[decoded[0] as String]!, decoded[1] as String),
    );
  });

  document.getElementById('selfcheck')?.onClick.listen((event) async {
    print('starting');
    final database = await WasmDatabase.open(
      databaseName: dbName,
      sqlite3Uri: sqlite3WasmUri,
      driftWorkerUri: driftWorkerUri,
      initializeDatabase: _initializeDatabase,
    );

    print('selected storage: ${database.chosenImplementation}');
    print('missing features: ${database.missingFeatures}');
  });
}

void _addCallbackForWebDriver(String name, Future Function(String?) impl) {
  setProperty(globalThis, name,
      allowInterop((String? arg, Function callback) async {
    Object? result;

    try {
      result = await impl(arg);
    } catch (e, s) {
      final console = getProperty(globalThis, 'console');
      callMethod(console, 'error', [e, s]);
    }

    callMethod(callback, 'call', [null, result]);
  }));
}

Future<Uint8List?> _initializeDatabase() async {
  switch (initializationMode) {
    case InitializationMode.loadAsset:
      final response = await http.get(Uri.parse('/initial.db'));
      return response.bodyBytes;

    case InitializationMode.migrateCustomWasmDatabase:

      // Let's first open a custom WasmDatabase, the way it would have been
      // done before WasmDatabase.open.
      final sqlite3 = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
      final fs = await IndexedDbFileSystem.open(dbName: dbName);
      sqlite3.registerVirtualFileSystem(fs, makeDefault: true);

      final wasmDb = WasmDatabase(sqlite3: sqlite3, path: 'app.db');
      final db = TestDatabase(wasmDb);
      await db
          .into(db.testTable)
          .insert(TestTableCompanion.insert(content: 'from old database'));
      await db.close();

      final (file: file, outFlags: _) = fs.xOpen(Sqlite3Filename('/app.db'), 0);
      final blob = Uint8List(file.xFileSize());
      file.xRead(blob, 0);
      file.xClose();
      fs.xDelete('/app.db', 0);
      await fs.close();

      return blob;
    case InitializationMode.none:
      return null;
  }
}

Future<String> _detectImplementations(String? _) async {
  final result = await WasmDatabase.probe(
    sqlite3Uri: sqlite3WasmUri,
    driftWorkerUri: driftWorkerUri,
    databaseName: dbName,
  );

  return json.encode({
    'impls': result.availableStorages.map((r) => r.name).toList(),
    'missing': result.missingFeatures.map((r) => r.name).toList(),
    'existing': result.existingDatabases.map((r) => [r.$1.name, r.$2]).toList(),
  });
}

Future<void> _open(String? implementationName) async {
  DatabaseConnection connection;

  if (implementationName != null) {
    final probeResult = await WasmDatabase.probe(
      sqlite3Uri: sqlite3WasmUri,
      driftWorkerUri: driftWorkerUri,
      databaseName: dbName,
    );

    connection = await probeResult.open(
      WasmStorageImplementation.values.byName(implementationName),
      dbName,
      initializeDatabase: _initializeDatabase,
    );
  } else {
    final result = await WasmDatabase.open(
      databaseName: dbName,
      sqlite3Uri: sqlite3WasmUri,
      driftWorkerUri: driftWorkerUri,
      initializeDatabase: _initializeDatabase,
      localSetup: (db) {
        // The worker has a similar setup call that will make database_host
        // return `worker` instead.
        db.createFunction(
          functionName: 'database_host',
          function: (args) => 'document',
          argumentCount: const AllowedArgumentCount(1),
        );
      },
    );

    connection = result.resolvedExecutor;
  }

  final db = openedDatabase = TestDatabase(connection);

  // Make sure it works!
  await db.customSelect('SELECT database_host()').get();

  tableUpdates = StreamQueue(db.testTable.all().watch());
  await tableUpdates!.next;
}

Future<void> _waitForUpdate(String? _) async {
  await tableUpdates!.next;
}

Future<void> _insert(String? _) async {
  final db = openedDatabase!;
  await db
      .into(db.testTable)
      .insert(TestTableCompanion.insert(content: DateTime.now().toString()));
}

Future<int> _getRows(String? _) async {
  final db = openedDatabase!;
  final count = countAll();

  final query = db.selectOnly(db.testTable)..addColumns([count]);
  return await query.map((row) => row.read(count)!).getSingle();
}
