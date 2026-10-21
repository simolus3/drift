import 'dart:async';

import 'package:async/async.dart';
import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:http/http.dart' as http;
import 'package:sqlite3/wasm.dart';
import 'package:web/web.dart'
    show document, window, EventStreamProviders, Window;
import 'package:web_wasm/initialization_mode.dart';
import 'package:web_wasm/src/database.dart';
import 'package:web_wasm/src/driver/protocol.dart';

const dbName = 'drift_test';
final sqlite3WasmUri = Uri.parse('sqlite3.wasm');
var driftWorkerUri = Uri.parse('worker.dart.js');

TestDatabase? openedDatabase;
StreamQueue<void>? tableUpdates;

InitializationMode initializationMode = InitializationMode.none;
int schemaVersion = 1;

void main() {
  if (Uri.base.queryParameters['client'] case final clientId?) {
    final id = int.parse(clientId);
    print('Detected client id: $clientId');

    final client = TestClient(http.Client());
    runZoned(
      () async {
        await for (final instruction in client.instructions(id)) {
          try {
            final command = commands[instruction.method]!;
            client.postCompletion(
              InstructionComplete(
                id: instruction.id,
                result: await command(instruction.arguments),
              ),
            );
          } catch (e, s) {
            client.postError(
              ClientError(
                id: instruction.id,
                message: e.toString(),
                trace: s.toString(),
              ),
            );
          }
        }
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) {
          parent.print(zone, line);
          client.print(ClientPrint(clientId: id, message: line));
        },
      ),
    );
  }

  _setupSelfcheckButton();
}

final commands = <String, Future<Object?> Function(Object?)>{
  'isDart2wasm': (_) async => const bool.fromEnvironment('dart.tool.dart2wasm'),
  'detectImplementations': (_) => _detectImplementations(),
  'detectImplementationsWrongUri': (_) {
    driftWorkerUri = Uri.parse('wrong.js');
    return _detectImplementations();
  },
  'open': (arg) {
    final {
      'implementation': implementation as String?,
      'moveToOpfs': moveToOpfs as bool,
    } = arg as Map;

    return _open(implementation, moveToOpfs);
  },
  'close': (_) async {
    await tableUpdates?.cancel();
    await openedDatabase?.close();
    return null;
  },
  'insert': (_) async {
    final db = openedDatabase!;
    await db
        .into(db.testTable)
        .insert(TestTableCompanion.insert(content: DateTime.now().toString()));
    return null;
  },
  'insertInTransaction': (_) async {
    final db = openedDatabase!;
    await db.transaction(() async {
      await db
          .into(db.testTable)
          .insert(TestTableCompanion.insert(content: 'from transaction'));
    });
    return null;
  },
  'insertReturning': (_) async {
    final db = openedDatabase!;
    await db
        .into(db.testTable)
        .insertReturning(TestTableCompanion.insert(content: 'returning'));
    return null;
  },
  'getRows': (_) async {
    final db = openedDatabase!;
    final count = countAll();

    final query = db.selectOnly(db.testTable)..addColumns([count]);
    return await query.map((row) => row.read(count)!).getSingle();
  },
  'hasTable': (_) async {
    final db = openedDatabase!;
    final rows = await db.customSelect('SELECT * FROM sqlite_schema').get();
    return rows.isNotEmpty;
  },
  'waitForUpdate': (_) async {
    await tableUpdates!.next;
    return null;
  },
  'enableInitialization': (arg) async {
    initializationMode = InitializationMode.values.byName(arg as String);
    return null;
  },
  'setSchemaVersion': (arg) async {
    schemaVersion = arg as int;
    return null;
  },
  'deleteDatabase': (arg) async {
    final result = await WasmDatabase.probe(
      sqlite3Uri: sqlite3WasmUri,
      driftWorkerUri: driftWorkerUri,
    );

    await result.deleteDatabase(_existingDatabase(arg));
    return null;
  },
  'exportDatabase': (arg) async {
    final result = await WasmDatabase.probe(
      sqlite3Uri: sqlite3WasmUri,
      driftWorkerUri: driftWorkerUri,
    );

    final exported = await result.exportDatabase(_existingDatabase(arg));
    return exported != null;
  },
  'doExclusive': (_) async {
    final database = openedDatabase!;
    await database.exclusively(() async {
      await database.transaction(() async {
        await database.testTable.insertOne(
          TestTableCompanion.insert(content: 'from exclusive'),
        );
      });
    });

    return null;
  },
  'lockForever': (_) async {
    final database = openedDatabase!;
    final hasLock = Completer<void>();

    database.exclusively(() async {
      hasLock.complete();
      return Completer().future;
    });

    await hasLock.future;
    return null;
  },
  'openWindow': (arg) async {
    final uri = arg as String;
    openedWindows[uri] = window.open(uri, '_blank')!;
    return null;
  },
  'closeWindow': (arg) async {
    openedWindows.remove(arg as String)!.close();
    return null;
  },
  'navigate': (arg) async {
    // The test driver doesn't wait for this to complete, the new page will
    // connect as a new client.
    window.location.href = arg as String;
    return null;
  },
};

/// Windows opened through the `openWindow` command, keyed by their URI.
final openedWindows = <String, Window>{};

void _setupSelfcheckButton() {
  final selfcheckBtn = document.getElementById('selfcheck')!;
  EventStreamProviders.clickEvent.forElement(selfcheckBtn).listen((
    event,
  ) async {
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

ExistingDatabase _existingDatabase(Object? arg) {
  final [api as String, name as String] = arg as List;
  return (WebStorageApi.byName[api]!, name);
}

Future<Uint8List?> _initializeDatabase() async {
  switch (initializationMode) {
    case InitializationMode.loadAsset:
      final response = await http.get(Uri.parse('/initial.db'));
      return response.bodyBytes;

    case InitializationMode.migrateCustomWasmDatabase:

      // Let's first open a custom WasmDatabase, the way it would have been
      // done before WasmDatabase.open.
      final sqlite3 = await WasmSqlite3.loadFromUrl(sqlite3WasmUri);
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
    case InitializationMode.noneAndDisableMigrations:
      return null;
  }
}

Future<Object?> _detectImplementations() async {
  final result = await WasmDatabase.probe(
    sqlite3Uri: sqlite3WasmUri,
    driftWorkerUri: driftWorkerUri,
    databaseName: dbName,
  );

  return {
    'impls': result.availableStorages.map((r) => r.name).toList(),
    'missing': result.missingFeatures.map((r) => r.name).toList(),
    'existing': result.existingDatabases.map((r) => [r.$1.name, r.$2]).toList(),
  };
}

void _setupDatabase(CommonDatabase db) {
  // The worker has a similar setup call that will make database_host return
  // `worker` instead.
  db.createFunction(
    functionName: 'database_host',
    function: (args) => 'document',
    argumentCount: const AllowedArgumentCount(0),
  );
}

Future<Object?> _open(
  String? implementationName,
  bool moveIndexedDbToOps,
) async {
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
      localSetup: _setupDatabase,
    );
  } else {
    final result = await WasmDatabase.open(
      databaseName: dbName,
      sqlite3Uri: sqlite3WasmUri,
      driftWorkerUri: driftWorkerUri,
      initializeDatabase: _initializeDatabase,
      enableMigrations:
          initializationMode != InitializationMode.noneAndDisableMigrations,
      moveExistingIndexedDbToOpfs: moveIndexedDbToOps,
      localSetup: _setupDatabase,
    );

    connection = result.resolvedExecutor;
  }

  final db = openedDatabase = TestDatabase(connection)
    ..schemaVersion = schemaVersion;

  // Make sure it works!
  await db.customSelect('SELECT database_host()').get();

  if (initializationMode != InitializationMode.noneAndDisableMigrations) {
    // Can't listen without migrations, the table doesn't exist.
    tableUpdates = StreamQueue(db.testTable.all().watch());
    await tableUpdates!.next;
  }
  return null;
}
