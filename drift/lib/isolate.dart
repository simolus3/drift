/// Contains utils to run drift databases in a background isolate.
///
/// Please note that this API is not supported on the web.
library isolate;

import 'dart:async';
import 'dart:isolate';

import 'package:meta/meta.dart';
import 'package:stream_channel/stream_channel.dart';

import 'drift.dart';
import 'remote.dart';
import 'src/isolate.dart';
import 'src/remote/protocol.dart';

export 'remote.dart' show DriftRemoteException;

/// Signature of a function that opens a database connection.
typedef DatabaseOpener = QueryExecutor Function();

/// Defines utilities to run drift in a background isolate. In the operation
/// mode created by these utilities, there's a single background isolate doing
/// all the work. Any other isolate can use the [connect] method to obtain an
/// instance of a [GeneratedDatabase] class that will delegate its work onto a
/// background isolate. Auto-updating queries, and transactions work across
/// isolates, and the user facing api is exactly the same.
///
/// Please note that, while running drift in a background isolate can reduce
/// lags in foreground isolates (thus removing UI jank), the overall database
/// performance will be worse. This is because result data is not available
/// directly and instead needs to be copied from the database isolate. Thanks
/// to recent improvements like isolate groups in the Dart VM, this overhead is
/// fairly small and using isolates to run drift queries is recommended where
/// possible.
///
/// The easiest way to use drift isolates is to use
/// `NativeDatabase.createInBackground`, which is a drop-in replacement for
/// `NativeDatabase` that uses a [DriftIsolate] under the hood.
///
/// Also, be aware that this api is not available on the web.
///
/// See also:
/// - [Isolate], for general information on multi threading in Dart.
/// - The [detailed documentation](https://drift.simonbinder.eu/docs/advanced-features/isolates),
///   which provides example codes on how to use this api.
class DriftIsolate {
  /// The underlying port used to establish a connection with this
  /// [DriftIsolate].
  ///
  /// This [SendPort] can safely be sent over isolates. The receiving isolate
  /// can reconstruct a [DriftIsolate] by using [DriftIsolate.fromConnectPort].
  final SendPort connectPort;

  /// The flag indicating whether messages between this [DriftIsolate]
  /// and the [DriftServer] should be serialized.
  final bool serialize;

  /// Creates a [DriftIsolate] talking to another isolate by using the
  /// [connectPort].
  ///
  /// {@template drift_isolate_serialize}
  /// Internally, drift uses ports from `dart:isolate` to send commands to an
  /// internal server dispatching database actions.
  /// In most setups, those ports can send and receive almost any Dart object.
  /// In special cases though, the platform only supports sending simple types
  /// across send types. In particular, isolates across different Flutter
  /// engines (such as the ones spawned by the `workmanager` package) are
  /// unable to handle most objects.
  /// To support those setups, drift can serialize its iground isolate doing
  /// all the work. Any other isolate can use the [connect] method to obtain an
  /// instance of a [GeneratedDatabase] class that will delegate its work onto a
  /// background isolate. Auto-updating queries, and transactions work across
  /// isolates, and the user facing api is exactly the same.
  ///
  /// Please note that, while running drift in a background isolate can reduce
  /// lags in foreground isolates (thus removing UI jank), the overall database
  /// performance will be worse. This is because result data is not available
  /// directly and instead needs to be copied from the database isolate. Thanks
  /// to recent improvements like isolate groups in the Dart VM, this overhead is
  /// fairly small and using isolates to run drift queries is recommended where
  /// possible.
  ///
  /// The easiest way to use drift isolates is to use
  /// `NativeDatabase.createInBackground`, which is a dropternal communication
  /// channel to only send simple types across isolates. The [serialize]
  /// parameter, which is enabled by default, controls this behavior.
  ///
  /// In most scenarios, [serialize] can be disabled for a considerable
  /// performance improvement.
  /// {@endtemplate}
  DriftIsolate.fromConnectPort(this.connectPort, {this.serialize = true});

  StreamChannel _open() {
    return connectToServer(connectPort, serialize);
  }

  /// Connects to this [DriftIsolate] from another isolate.
  ///
  /// All operations on the returned [DatabaseConnection] will be executed on a
  /// background isolate.
  ///
  /// When [singleClientMode] is enabled (it defaults to `false`), drift assumes
  /// that the isolate will only be connected to once. In this mode, drift will
  /// shutdown the remote isolate once the returned [DatabaseConnection] is
  /// closed.
  /// Also, stream queries are more efficient when this mode is enables since we
  /// don't have to synchronize table updates to other clients (since there are
  /// none).
  ///
  /// Setting the [isolateDebugLog] is only helpful when debugging drift itself.
  /// It will print messages exchanged between the two isolates.
  Future<DatabaseConnection> connect({
    bool isolateDebugLog = false,
    bool singleClientMode = false,
  }) async {
    final connection = await connectToRemoteAndInitialize(
      _open(),
      debugLog: isolateDebugLog,
      serialize: serialize,
      singleClientMode: singleClientMode,
    );

    return DatabaseConnection(connection.executor,
        streamQueries: connection.streamQueries, connectionData: this);
  }

  /// Stops the background isolate and disconnects all [DatabaseConnection]s
  /// created.
  /// If you only want to disconnect a database connection created via
  /// [connect], use [GeneratedDatabase.close] instead.
  Future<void> shutdownAll() {
    return shutdown(_open(), serialize: serialize);
  }

  /// Creates a new [DriftIsolate] on a background thread.
  ///
  /// The [opener] function will be used to open the [DatabaseConnection] used
  /// by the isolate.
  ///
  /// Because [opener] will be called on another isolate with its own memory,
  /// it must either be a top-level member or a static class method.
  ///
  /// To close the isolate later, use [shutdownAll]. Or, if you know that only
  /// a single client will connect, set `singleClientMode: true` in [connect].
  /// That way, the drift isolate will shutdown when the client is closed.
  ///
  /// The optional [isolateSpawn] parameter can be used to make drift use
  /// something else instead of [Isolate.spawn] to spawn the isolate. This may
  /// be useful if you want to set additional options on the isolate or
  /// otherwise need a reference to it.
  ///
  /// {@macro drift_isolate_serialize}
  static Future<DriftIsolate> spawn(
    DatabaseOpener opener, {
    bool serialize = false,
    Future<Isolate> Function<T>(void Function(T), T) isolateSpawn =
        Isolate.spawn,
  }) async {
    final receiveServer = ReceivePort('drift isolate connect');
    final keyFuture = receiveServer.first;

    await isolateSpawn(_startDriftIsolate, [receiveServer.sendPort, opener]);
    final key = await keyFuture as SendPort;
    return DriftIsolate.fromConnectPort(key, serialize: serialize);
  }

  /// Creates a [DriftIsolate] in the [Isolate.current] isolate. The returned
  /// [DriftIsolate] is an object than can be sent across isolates - any other
  /// isolate can then use [DriftIsolate.connect] to obtain a special database
  /// connection which operations are all executed on this isolate.
  ///
  /// When [killIsolateWhenDone] is enabled (it defaults to `false`) and
  /// [shutdownAll] is called on the returned [DriftIsolate], the isolate used
  /// to call [DriftIsolate.inCurrent] will be killed.
  ///
  /// {@macro drift_isolate_serialize}
  factory DriftIsolate.inCurrent(DatabaseOpener opener,
      {bool killIsolateWhenDone = false, bool serialize = false}) {
    final server = RunningDriftServer(Isolate.current, opener(),
        killIsolateWhenDone: killIsolateWhenDone);
    return DriftIsolate.fromConnectPort(
      server.portToOpenConnection,
      serialize: serialize,
    );
  }
}

/// Experimental methods to connect to an existing drift database from different
/// isolates.
extension ComputeWithDriftIsolate<DB extends DatabaseConnectionUser> on DB {
  /// Creates a [DriftIsolate] that, when connected to, will run queries on the
  /// database already opened by `this`.
  ///
  /// This can be used to share existing database across isolates, as instances
  /// of generated database classes can't be sent across isolates by default. A
  /// [DriftIsolate] can be sent over ports though, which enables a concise way
  /// to open a temporary isolate that is using an existing database:
  ///
  /// ```dart
  /// Future<void> main() async {
  ///   final database = MyDatabase(...);
  ///
  ///   // This is illegal - MyDatabase is not serializable
  ///   await Isolate.run(() async {
  ///     await database.batch(...);
  ///   });
  ///
  ///   // This will work. Only the `connection` is sent to the new isolate. By
  ///   // creating a new database instance based on the connection, the same
  ///   // logical database can be shared across isolates.
  ///   final connection = await database.serializableConnection();
  ///   await Isolate.run(() async {
  ///      final database = MyDatabase(await connection.connect());
  ///      await database.batch(...);
  ///   });
  /// }
  /// ```
  ///
  /// The example of running a short-lived database for a single task unit
  /// requiring a database is also available through [computeWithDatabase].
  @experimental
  Future<DriftIsolate> serializableConnection() async {
    // ignore: invalid_use_of_protected_member
    final localConnection = connection;
    final data = await localConnection.connectionData;

    if (data is DriftIsolate) {
      // The local database is already connected to an isolate, use that one
      // directly.
      return data;
    } else {
      // Set up a drift server acting as a proxy to the existing database
      // connection.
      final server = RunningDriftServer(
        Isolate.current,
        localConnection,
        onlyAcceptSingleConnection: true,
        closeConnectionAfterShutdown: false,
        killIsolateWhenDone: false,
      );

      // Since the existing database didn't use an isolate server, we need to
      // manually forward stream query updates.
      final forwardToServer = tableUpdates().listen((localUpdates) {
        server.server.dispatchTableUpdateNotification(
            NotifyTablesUpdated(localUpdates.toList()));
      });
      final forwardToLocal =
          server.server.tableUpdateNotifications.listen((remoteUpdates) {
        notifyUpdates(remoteUpdates.updates.toSet());
      });
      server.server.done.whenComplete(() {
        forwardToServer.cancel();
        forwardToLocal.cancel();
      });

      return DriftIsolate.fromConnectPort(
        server.portToOpenConnection,
        serialize: false,
      );
    }
  }

  /// Spawns a short-lived isolate to run the [computation] with a drift
  /// database.
  ///
  /// Essentially, this is a variant of [Isolate.run] for computations that also
  /// need to share a drift database between them. As drift databases are
  /// stateful objects, they can't be send across isolates (and thus used in
  /// [Isolate.run] or Flutter's `compute`) without special setup.
  ///
  /// This method will extract the underlying database connection of `this`
  /// database into a form that can be serialized across isolates. Then,
  /// [Isolate.run] will be called to invoke [computation]. The [connect]
  /// function is responsible for creating an instance of your database class
  /// from the low-level connection.
  ///
  /// As an example, consider a database class:
  ///
  /// ```dart
  /// class MyDatabase extends $MyDatabase {
  ///   MyDatabase(QueryExecutor executor): super(executor);
  /// }
  /// ```
  ///
  /// [computeWithDatabase] can then be used to access an instance of
  /// `MyDatabase` in a new isolate, even though `MyDatabase` is not generally
  /// sharable between isolates:
  ///
  /// ```dart
  /// Future<void> loadBulkData(MyDatabase db) async {
  ///   await db.computeWithDatabase(
  ///     connect: MyDatabase.new,
  ///     computation: (db) async {
  ///       // This computation has access to a second `db` that is internally
  ///       // linked to the original database.
  ///       final data = await fetchRowsFromNetwork();
  ///       await db.batch((batch) {
  ///         // More expensive work like inserting data
  ///       });
  ///     },
  ///   );
  /// }
  /// ```
  @experimental
  Future<Ret> computeWithDatabase<Ret>({
    required FutureOr<Ret> Function(DB) computation,
    required DB Function(DatabaseConnection) connect,
  }) async {
    final connection = await serializableConnection();

    return await Isolate.run(() async {
      final database = connect(await connection.connect());
      try {
        return await computation(database);
      } finally {
        await database.close();
      }
    });
  }
}

/// Creates a [RunningDriftServer] and sends a [SendPort] that can be used to
/// establish connections.
///
/// Te [args] list must contain two elements. The first one is the [SendPort]
/// that [_startDriftIsolate] will use to send the new [SendPort] used to
/// establish further connections. The second element is a [DatabaseOpener]
/// used to open the underlying database connection.
void _startDriftIsolate(List args) {
  final sendPort = args[0] as SendPort;
  final opener = args[1] as DatabaseOpener;

  final server = RunningDriftServer(Isolate.current, opener());
  sendPort.send(server.portToOpenConnection);
}
