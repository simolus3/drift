/// @docImport 'dart:isolate';
/// @docImport '../native.dart';
library;

import 'dart:async';

import 'package:drift3_preview/drift.dart';

import 'compute_with_database/unsupported.dart'
    if (dart.library.ffi) 'compute_with_database/supported.dart';

/// Extension providing [computeWithDatabase] to run computations using a drift
/// database on a background isolate.
extension ComputeWithDatabaseExtension on GeneratedDatabase {
  /// When using a [sqliteConnectionPool],this spawns a short-lived isolate to
  /// run the [computation] with a drift database.
  ///
  /// For other database implementations, this will run the [computation] on the
  /// current JavaScript context.
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
  ///   MyDatabase(super.implementation);
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
  /// Note that with the recommended setup of [sqliteConnectionPool], drift will
  /// already use an isolate to run your SQL statements. Using
  /// [computeWithDatabase] is beneficial when an an expensive work unit needs
  /// to use the database, or when creating the SQL statements itself is
  /// expensive.
  Future<Ret> computeWithDatabase<Ret, DB extends GeneratedDatabase>({
    required FutureOr<Ret> Function(DB) computation,
    required DB Function(DriftConnection) connect,
  }) => computeWithDatabaseImplementation(
    computation: computation,
    connect: connect,
    database: this as DB,
  );
}
