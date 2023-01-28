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

// #docregion database
@DriftDatabase(/*...*/)
class TodoDb extends _$TodoDb {
  // Your existing constructor, whatever it may be...
  TodoDb(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;
}
// #enddocregion database

// #docregion isolate
void main() async {
  // create a drift executor in a new background isolate. If you want to start
  // the isolate yourself, you can also call DriftIsolate.inCurrent() from the
  // background isolate
  final isolate = await DriftIsolate.spawn(() {
    // This callback needs to return the database connection used by the drift
    // isolate. This example uses a non-persistent in-memory database, but you
    // can also use your existing NativeDatabase with a file as well.
    return DatabaseConnection(NativeDatabase.memory());
  });

  // we can now create a database connection that will use the isolate
  // internally. This is NOT what we returned from _backgroundConnection, drift
  // uses an internal proxy class for isolate communication.
  // As long as the isolate is used by only one database (it is here), we can
  // use `singleClientMode` to dispose the isolate after closing the connection.
  final connection = await isolate.connect(singleClientMode: true);

  final db = TodoDb(connection);

  // you can now use your database exactly like you regularly would, it
  // transparently uses a background isolate internally
  // #enddocregion isolate
  // Just using the db to avoid an analyzer error, this isn't part of the docs.
  db.customSelect('SELECT 1');
  // #docregion isolate
}
// #enddocregion isolate

void connectSynchronously() {
  // #docregion delayed
  TodoDb(
    DatabaseConnection.delayed(Future.sync(() async {
      final isolate = await DriftIsolate.spawn(() {
        return DatabaseConnection(NativeDatabase.memory());
      });
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
