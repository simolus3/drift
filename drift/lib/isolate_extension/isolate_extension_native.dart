/// Contains utils to run drift databases in a background isolate.
///
/// Please note that some APIs are not supported on web.
library;

import 'dart:async';
import 'dart:isolate';

import 'package:drift/isolate.dart';
import 'package:meta/meta.dart';

import '../drift.dart';
import '../src/isolate.dart';
import '../src/remote/protocol.dart';

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
    final currentlyInRootConnection = resolvedEngine is GeneratedDatabase;
    // ignore: invalid_use_of_protected_member
    final localConnection = resolvedEngine.connection;
    final data = await localConnection.connectionData;

    // If we're connected to an isolate already, we can use that one directly
    // instead of starting a short-lived drift server.
    // However, this does not work if [serializableConnection] is called in a
    // transaction zone, since the top-level connection could be blocked waiting
    // for the transaction (as transactions can't be concurrent in sqlite3).
    if (data is DriftIsolate && currentlyInRootConnection) {
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

  /// On native platforms this spawns a short-lived isolate to run the [computation] with a drift
  /// database.
  /// On web platforms this will run the [computation] on the current eventloop.
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
  ///
  /// Note that with the recommended setup of `NativeDatabase.createInBackground`,
  /// drift will already use an isolate to run your SQL statements. Using
  /// [computeWithDatabase] is beneficial when an an expensive work unit needs
  /// to use the database, or when creating the SQL statements itself is
  /// expensive.
  /// In particular, note that [computeWithDatabase] does not create a second
  /// database connection to sqlite3 - the current one is re-used. So if you're
  /// using a synchronous database connection, using this method is unlikely to
  /// take significant loads off the main isolate. For that reason, the use of
  /// `NativeDatabase.createInBackground` is encouraged.
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
