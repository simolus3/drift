import 'dart:io';

import 'package:meta/meta.dart';
import 'package:moor/backends.dart';
import 'package:moor/moor.dart';
import 'package:sqlite3/sqlite3.dart';

import 'database_tracker.dart';
import 'moor_ffi_functions.dart';

/// Signature of a function that can perform setup work on a [database] before
/// moor is fully ready.
///
/// This could be used to, for instance, set encryption keys for SQLCipher
/// implementations.
typedef DatabaseSetup = void Function(Database database);

/// A moor database that runs on the Dart VM.
class VmDatabase extends DelegatedDatabase {
  VmDatabase._(DatabaseDelegate delegate, bool logStatements)
      : super(delegate, isSequential: true, logStatements: logStatements);

  /// Creates a database that will store its result in the [file], creating it
  /// if it doesn't exist.
  ///
  /// {@template moor_vm_database_factory}
  /// If [logStatements] is true (defaults to `false`), generated sql statements
  /// will be printed before executing. This can be useful for debugging.
  /// The optional [setup] function can be used to perform a setup just after
  /// the database is opened, before moor is fully ready. This can be used to
  /// add custom user-defined sql functions or to provide encryption keys in
  /// SQLCipher implementations.
  /// {@endtemplate}
  factory VmDatabase(File file,
      {bool logStatements = false, DatabaseSetup? setup}) {
    return VmDatabase._(_VmDelegate(file, setup), logStatements);
  }

  /// Creates an in-memory database won't persist its changes on disk.
  ///
  /// {@macro moor_vm_database_factory}
  factory VmDatabase.memory(
      {bool logStatements = false, DatabaseSetup? setup}) {
    return VmDatabase._(_VmDelegate(null, setup), logStatements);
  }

  /// Creates a moor executor for an opened [database] from the `sqlite3`
  /// package.
  ///
  /// Closing the returned [VmDatabase] will also dispose the database passed to
  /// this factory.
  ///
  /// {@macro moor_vm_database_factory}
  factory VmDatabase.opened(Database database,
      {bool logStatements = false, DatabaseSetup? setup}) {
    return VmDatabase._(_VmDelegate._opened(database, setup), logStatements);
  }

  /// Disposes resources allocated by all `VmDatabase` instances of this
  /// process.
  ///
  /// This method will call `sqlite3_close_v2` for every `VmDatabase` that this
  /// process has opened without closing later.
  ///
  /// __Warning__: This functionality appears to cause crashes on iOS, and it
  /// does nothing on Android. It's mainly intended for Desktop operating
  /// systems, so try to avoid calling it where it's not necessary.
  /// For safety measures, avoid calling [closeExistingInstances] in release
  /// builds.
  ///
  /// Ideally, all databases should be closed properly in Dart. In that case,
  /// it's not necessary to call [closeExistingInstances]. However, features
  /// like hot (stateless) restart can make it impossible to reliably close
  /// every database. In that case, we leak native sqlite3 database connections
  /// that aren't referenced by any Dart object. Moor can track those
  /// connections across Dart VM restarts by storing them in an in-memory sqlite
  /// database.
  /// Calling this method can cleanup resources and database locks after a
  /// restart.
  ///
  /// Note that calling [closeExistingInstances] when you're still actively
  /// using a [VmDatabase] can lead to crashes, since the database would then
  /// attempt to use an invalid connection.
  /// This, this method should only be called when you're certain that there
  /// aren't any active [VmDatabase]s, not even on another isolate.
  ///
  /// A suitable place to call [closeExistingInstances] is at an early stage
  /// of your `main` method, before you're using moor.
  ///
  /// ```dart
  /// void main() {
  ///   // Guard against zombie database connections caused by hot restarts
  ///   assert(() {
  ///     VmDatabase.closeExistingInstances();
  ///     return true;
  ///   }());
  ///
  ///   runApp(MyApp());
  /// }
  /// ```
  ///
  /// For more information, see [issue 835](https://github.com/simolus3/moor/issues/835).
  @experimental
  static void closeExistingInstances() {
    tracker.closeExisting();
  }
}

class _VmDelegate extends DatabaseDelegate {
  late Database _db;

  bool _hasCreatedDatabase = false;
  bool _isOpen = false;

  final File? file;
  final DatabaseSetup? setup;

  _VmDelegate(this.file, this.setup);

  _VmDelegate._opened(this._db, this.setup)
      : file = null,
        _hasCreatedDatabase = true {
    _initializeDatabase();
  }

  @override
  TransactionDelegate get transactionDelegate => const NoTransactionDelegate();

  @override
  late DbVersionDelegate versionDelegate;

  @override
  Future<bool> get isOpen => Future.value(_isOpen);

  @override
  Future<void> open(QueryExecutorUser user) async {
    if (!_hasCreatedDatabase) {
      _createDatabase();
      _initializeDatabase();
    }

    _isOpen = true;
    return Future.value();
  }

  void _createDatabase() {
    assert(!_hasCreatedDatabase);
    _hasCreatedDatabase = true;

    final file = this.file;
    if (file != null) {
      // Create the parent directory if it doesn't exist. sqlite will emit
      // confusing misuse warnings otherwise
      final dir = file.parent;
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      _db = sqlite3.open(file.path);
      tracker.markOpened(file.path, _db);
    } else {
      _db = sqlite3.openInMemory();
    }
  }

  void _initializeDatabase() {
    _db.useMoorVersions();
    setup?.call(_db);
    versionDelegate = _VmVersionDelegate(_db);
  }

  @override
  Future<void> runBatched(BatchedStatements statements) async {
    final prepared = [
      for (final stmt in statements.statements) _db.prepare(stmt),
    ];

    for (final application in statements.arguments) {
      final stmt = prepared[application.statementIndex];

      stmt.execute(application.arguments);
    }

    for (final stmt in prepared) {
      stmt.dispose();
    }

    return Future.value();
  }

  Future _runWithArgs(String statement, List<Object?> args) async {
    if (args.isEmpty) {
      _db.execute(statement);
    } else {
      final stmt = _db.prepare(statement);
      stmt.execute(args);
      stmt.dispose();
    }
  }

  @override
  Future<void> runCustom(String statement, List<Object?> args) async {
    await _runWithArgs(statement, args);
  }

  @override
  Future<int> runInsert(String statement, List<Object?> args) async {
    await _runWithArgs(statement, args);
    return _db.lastInsertRowId;
  }

  @override
  Future<int> runUpdate(String statement, List<Object?> args) async {
    await _runWithArgs(statement, args);
    return _db.getUpdatedRows();
  }

  @override
  Future<QueryResult> runSelect(String statement, List<Object?> args) async {
    final stmt = _db.prepare(statement);
    final result = stmt.select(args);
    stmt.dispose();

    return Future.value(QueryResult.fromRows(result.toList()));
  }

  @override
  Future<void> close() async {
    _db.dispose();
    tracker.markClosed(_db);
  }
}

class _VmVersionDelegate extends DynamicVersionDelegate {
  final Database database;

  _VmVersionDelegate(this.database);

  @override
  Future<int> get schemaVersion => Future.value(database.userVersion);

  @override
  Future<void> setSchemaVersion(int version) {
    database.userVersion = version;
    return Future.value();
  }
}
