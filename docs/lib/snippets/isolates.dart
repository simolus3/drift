import 'dart:io';
import 'dart:isolate';

import 'package:drift/drift.dart';
// #docregion isolate
import 'package:drift/isolate.dart';
// #enddocregion isolate
import 'package:drift/native.dart';
// #docregion initialization
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
// #enddocregion initialization

part 'isolates.g.dart';

QueryExecutor _openConnection() {
  return NativeDatabase.memory();
}

class SomeTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text()();
}

// Copying the definitions here because we can't import Flutter in documentation
// snippets.
class RootIsolateToken {
  static RootIsolateToken? instance;
}

class BackgroundIsolateBinaryMessenger {
  static void ensureInitialized(RootIsolateToken token) {}
}

// #docregion isolate, database-definition

@DriftDatabase(tables: [SomeTable] /* ... */)
class MyDatabase extends _$MyDatabase {
  // A constructor like this can use the default connection as described in the
  // getting started guide, but also allows overriding the connection.
  MyDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;
}
// #enddocregion isolate, database-definition

// #docregion driftisolate-spawn
Future<DriftIsolate> createIsolateWithSpawn() async {
  final token = RootIsolateToken.instance!;
  return await DriftIsolate.spawn(() {
    // This function runs in a new isolate, so we must first initialize the
    // messenger to use platform channels.
    BackgroundIsolateBinaryMessenger.ensureInitialized(token);

    // The callback to DriftIsolate.spawn() must return the database connection
    // to use.
    return LazyDatabase(() async {
      // Note that this runs on a background isolate, which only started to
      // support platform channels in Flutter 3.7. For earlier Flutter versions,
      // a workaround is described later in this article.
      final dbFolder = await getApplicationDocumentsDirectory();
      final path = p.join(dbFolder.path, 'app.db');

      return NativeDatabase(File(path));
    });
  });
}
// #enddocregion driftisolate-spawn

// #docregion custom-spawn
Future<DriftIsolate> createIsolateManually() async {
  final receiveIsolate = ReceivePort('receive drift isolate handle');
  await Isolate.spawn<SendPort>((message) async {
    final server = DriftIsolate.inCurrent(() {
      // Again, this needs to return the LazyDatabase or the connection to use.
      // #enddocregion custom-spawn
      throw 'stub';
      // #docregion custom-spawn
    });

    // Now, inform the original isolate about the created server:
    message.send(server);
  }, receiveIsolate.sendPort);

  final server = await receiveIsolate.first as DriftIsolate;
  receiveIsolate.close();
  return server;
}
// #enddocregion custom-spawn

Future<DriftIsolate> createIsolate() => createIsolateWithSpawn();

// #docregion isolate
void main() async {
  final isolate = await createIsolate();

  // After creating the isolate, calling connect() will return a connection
  // which can be used to create a database.
  // As long as the isolate is used by only one database (it is here), we can
  // use `singleClientMode` to dispose the isolate after closing the connection.
  final database = MyDatabase(await isolate.connect(singleClientMode: true));

  // you can now use your database exactly like you regularly would, it
  // transparently uses a background isolate to execute queries.
  // #enddocregion isolate
  // Just using the db to avoid an analyzer error, this isn't part of the docs.
  database.customSelect('SELECT 1');
  // #docregion isolate
}
// #enddocregion isolate

void connectSynchronously() {
  // #docregion delayed
  MyDatabase(
    DatabaseConnection.delayed(Future.sync(() async {
      final isolate = await createIsolate();
      return isolate.connect(singleClientMode: true);
    })),
  );
  // #enddocregion delayed
}

// #docregion initialization

Future<DriftIsolate> _createDriftIsolate() async {
  // this method is called from the main isolate. Since we can't use
  // getApplicationDocumentsDirectory on a background isolate, we calculate
  // the database path in the foreground isolate and then inform the
  // background isolate about the path.
  final dir = await getApplicationDocumentsDirectory();
  final path = p.join(dir.path, 'db.sqlite');
  final receivePort = ReceivePort();

  await Isolate.spawn(
    _startBackground,
    _IsolateStartRequest(receivePort.sendPort, path),
  );

  // _startBackground will send the DriftIsolate to this ReceivePort
  return await receivePort.first as DriftIsolate;
}

void _startBackground(_IsolateStartRequest request) {
  // this is the entry point from the background isolate! Let's create
  // the database from the path we received
  final executor = NativeDatabase(File(request.targetPath));
  // we're using DriftIsolate.inCurrent here as this method already runs on a
  // background isolate. If we used DriftIsolate.spawn, a third isolate would be
  // started which is not what we want!
  final driftIsolate = DriftIsolate.inCurrent(
    () => DatabaseConnection(executor),
  );
  // inform the starting isolate about this, so that it can call .connect()
  request.sendDriftIsolate.send(driftIsolate);
}

// used to bundle the SendPort and the target path, since isolate entry point
// functions can only take one parameter.
class _IsolateStartRequest {
  final SendPort sendDriftIsolate;
  final String targetPath;

  _IsolateStartRequest(this.sendDriftIsolate, this.targetPath);
}
// #enddocregion initialization

// #docregion init_connect
DatabaseConnection createDriftIsolateAndConnect() {
  return DatabaseConnection.delayed(Future.sync(() async {
    final isolate = await _createDriftIsolate();
    return await isolate.connect(singleClientMode: true);
  }));
}
// #enddocregion init_connect

// #docregion simple
QueryExecutor createSimple() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'db.sqlite'));

    // Using createInBackground creates a drift isolate with the recommended
    // options behind the scenes.
    return NativeDatabase.createInBackground(file);
  });
}
// #enddocregion simple

// #docregion invalid
Future<void> invalidIsolateUsage() async {
  final database = MyDatabase(NativeDatabase.memory());

  // Unfortunately, this doesn't work: Drift databases contain references to
  // async primitives like streams and futures that can't be serialized across
  // isolates like this.
  await Isolate.run(() async {
    await database.batch((batch) {
      // ...
    });
  });
}
// #enddocregion invalid

Future<List<SomeTableData>> _complexAndExpensiveOperationToFetchRows() async {
  throw 'stub';
}

// #docregion compute
Future<void> insertBulkData(MyDatabase database) async {
  // computeWithDatabase is an extension provided by package:drift/isolate.dart
  await database.computeWithDatabase(
    computation: (database) async {
      // Expensive computation that runs on its own isolate but talks to the
      // main database.
      final rows = await _complexAndExpensiveOperationToFetchRows();
      await database.batch((batch) {
        batch.insertAll(database.someTable, rows);
      });
    },
    connect: (connection) {
      // This function is responsible for creating a second instance of your
      // database class with a short-lived [connection].
      // For this to work, your database class needs to have a constructor that
      // allows taking a connection as described above.
      return MyDatabase(connection);
    },
  );
}
// #enddocregion compute

// #docregion custom-compute
Future<void> customIsolateUsage(MyDatabase database) async {
  final connection = await database.serializableConnection();

  await Isolate.run(
    () async {
      // We can't share the [database] object across isolates, but the connection
      // is fine!
      final databaseForIsolate = MyDatabase(await connection.connect());

      try {
        await databaseForIsolate.batch((batch) {
          // (...)
        });
      } finally {
        databaseForIsolate.close();
      }
    },
    debugName: 'My custom database task',
  );
}
// #enddocregion custom-compute
