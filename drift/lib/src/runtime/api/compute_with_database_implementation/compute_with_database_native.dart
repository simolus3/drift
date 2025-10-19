import 'dart:async';
import 'dart:isolate';

import 'package:drift/isolate.dart';
import 'package:drift/src/runtime/api/runtime_api.dart';

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
Future<Ret>
    computeWithDatabaseImplementation<Ret, DB extends GeneratedDatabase>({
  required FutureOr<Ret> Function(DB) computation,
  required DB Function(DatabaseConnection) connect,
  required DB database,
}) async {
  final connection = await database.serializableConnection();

  return await Isolate.run(() async {
    final database = connect(await connection.connect());
    try {
      return await computation(database);
    } finally {
      await database.close();
    }
  });
}
