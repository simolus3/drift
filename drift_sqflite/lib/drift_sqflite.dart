/// Flutter implementation for the drift database packages.
///
/// The [SqfliteQueryExecutor] class can be used as a drift database
/// implementation based on the `sqflite` package.
library drift_sqflite;

import 'dart:async';
import 'dart:io';

import 'package:drift/backends.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as s;

/// Signature of a function that runs when a database doesn't exist on file.
/// This can be useful to, for instance, load the database from an asset if it
/// doesn't exist.
typedef DatabaseCreator = FutureOr<void> Function(File file);

class _SqfliteDelegate extends DatabaseDelegate {
  late s.Database db;
  bool _isOpen = false;

  final bool inDbFolder;
  final String path;

  bool singleInstance;
  final DatabaseCreator? creator;

  _SqfliteDelegate(this.inDbFolder, this.path,
      {this.singleInstance = true, this.creator});

  @override
  late final DbVersionDelegate versionDelegate = _SqfliteVersionDelegate(db);

  @override
  TransactionDelegate get transactionDelegate => const NoTransactionDelegate();

  @override
  bool get isOpen => _isOpen;

  @override
  Future<void> open(QueryExecutorUser user) async {
    String resolvedPath;
    if (inDbFolder) {
      resolvedPath = join(await s.getDatabasesPath(), path);
    } else {
      resolvedPath = path;
    }

    final file = File(resolvedPath);
    if (creator != null && !await file.exists()) {
      await creator!(file);
    }

    // default value when no migration happened
    db = await s.openDatabase(
      resolvedPath,
      singleInstance: singleInstance,
    );
    _isOpen = true;
  }

  @override
  Future<void> close() {
    return db.close();
  }

  @override
  Future<void> runBatched(BatchedStatements statements) async {
    final batch = db.batch();

    for (final arg in statements.arguments) {
      batch.execute(statements.statements[arg.statementIndex], arg.arguments);
    }

    await batch.commit(noResult: true);
  }

  @override
  Future<void> runCustom(String statement, List<Object?> args) {
    return db.execute(statement, args);
  }

  @override
  Future<int> runInsert(String statement, List<Object?> args) {
    return db.rawInsert(statement, args);
  }

  @override
  Future<QueryResult> runSelect(String statement, List<Object?> args) async {
    final result = await db.rawQuery(statement, args);
    return QueryResult.fromRows(result);
  }

  @override
  Future<int> runUpdate(String statement, List<Object?> args) {
    return db.rawUpdate(statement, args);
  }
}

class _SqfliteVersionDelegate extends DynamicVersionDelegate {
  final s.Database _db;

  _SqfliteVersionDelegate(this._db);

  @override
  Future<int> get schemaVersion async {
    final result = await _db.rawQuery('PRAGMA user_version;');
    return result.single.values.first as int;
  }

  @override
  Future<void> setSchemaVersion(int version) async {
    await _db.rawUpdate('PRAGMA user_version = $version;');
  }
}

/// A query executor that uses sqflite internally.
class SqfliteQueryExecutor extends DelegatedDatabase {
  /// A query executor that will store the database in the file declared by
  /// [path]. If [logStatements] is true, statements sent to the database will
  /// be [print]ed, which can be handy for debugging. The [singleInstance]
  /// parameter sets the corresponding parameter on [s.openDatabase].
  /// The [creator] will be called when the database file doesn't exist. It can
  /// be used to, for instance, populate default data from an asset. Note that
  /// migrations might behave differently when populating the database this way.
  /// For instance, a database created by an [creator] will not receive the
  /// [MigrationStrategy.onCreate] callback because it hasn't been created by
  /// drift.
  SqfliteQueryExecutor(
      {required String path,
      bool? logStatements,
      bool singleInstance = true,
      DatabaseCreator? creator})
      : super(
            _SqfliteDelegate(false, path,
                singleInstance: singleInstance, creator: creator),
            logStatements: logStatements);

  /// A query executor that will store the database in the file declared by
  /// [path], which will be resolved relative to [s.getDatabasesPath()].
  /// If [logStatements] is true, statements sent to the database will
  /// be [print]ed, which can be handy for debugging. The [singleInstance]
  /// parameter sets the corresponding parameter on [s.openDatabase].
  /// The [creator] will be called when the database file doesn't exist. It can
  /// be used to, for instance, populate default data from an asset. Note that
  /// migrations might behave differently when populating the database this way.
  /// For instance, a database created by an [creator] will not receive the
  /// [MigrationStrategy.onCreate] callback because it hasn't been created by
  /// drift.
  SqfliteQueryExecutor.inDatabaseFolder(
      {required String path,
      bool? logStatements,
      bool singleInstance = true,
      DatabaseCreator? creator})
      : super(
            _SqfliteDelegate(true, path,
                singleInstance: singleInstance, creator: creator),
            logStatements: logStatements);

  /// The underlying sqflite [s.Database] object used by drift to send queries.
  ///
  /// Using the sqflite database can cause unexpected behavior in drift. For
  /// instance, stream queries won't update for updates sent to the [s.Database]
  /// directly. Further, drift assumes full control over the database for its
  /// internal connection management.
  /// For this reason, projects shouldn't use this getter unless they absolutely
  /// need to. The database is exposed to make migrating from sqflite to drift
  /// easier.
  ///
  /// Note that this returns null until the drifft database has been opened.
  /// A drift database is opened lazily when the first query runs.
  s.Database? get sqfliteDb {
    final sqfliteDelegate = delegate as _SqfliteDelegate;
    return sqfliteDelegate.isOpen ? sqfliteDelegate.db : null;
  }

  @override
  // We're not really required to be sequential since sqflite has an internal
  // lock to bring statements into a sequential order.
  // Setting isSequential here helps with cancellations in stream queries
  // though.
  bool get isSequential => true;
}
