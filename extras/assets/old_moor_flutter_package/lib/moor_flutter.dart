/// Flutter implementation for the moor database. This library merely provides
/// a thin level of abstraction between the
/// [sqflite](https://pub.dev/packages/sqflite) library and
/// [moor](https://github.com/simolus3/drift)
library moor_flutter;

import 'dart:async';
import 'dart:io';

import 'package:moor/backends.dart';
import 'package:moor/moor.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as s;

export 'package:moor/moor.dart';

/// Signature of a function that runs when a database doesn't exist on file.
/// This can be useful to, for instance, load the database from an asset if it
/// doesn't exist.
typedef DatabaseCreator = FutureOr<void> Function(File file);

class _SqfliteDelegate extends DatabaseDelegate with _SqfliteExecutor {
  @override
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
  TransactionDelegate get transactionDelegate =>
      _SqfliteTransactionDelegate(this);

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

class _SqfliteTransactionDelegate extends SupportedTransactionDelegate {
  final _SqfliteDelegate delegate;

  _SqfliteTransactionDelegate(this.delegate);

  @override
  void startTransaction(Future<void> Function(QueryDelegate) run) {
    delegate.db.transaction((transaction) async {
      final executor = _SqfliteTransactionExecutor(transaction);
      await run(executor);
    }).catchError((_) {
      // Ignore the error! We send a fake exception to indicate a rollback.
      // sqflite will rollback, but the exception will bubble up. Here we stop
      // the exception.
    });
  }
}

class _SqfliteTransactionExecutor extends QueryDelegate with _SqfliteExecutor {
  @override
  final s.DatabaseExecutor db;

  _SqfliteTransactionExecutor(this.db);
}

mixin _SqfliteExecutor on QueryDelegate {
  s.DatabaseExecutor get db;

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

/// A query executor that uses sqflite internally.
class FlutterQueryExecutor extends DelegatedDatabase {
  /// A query executor that will store the database in the file declared by
  /// [path]. If [logStatements] is true, statements sent to the database will
  /// be [print]ed, which can be handy for debugging. The [singleInstance]
  /// parameter sets the corresponding parameter on [s.openDatabase].
  /// The [creator] will be called when the database file doesn't exist. It can
  /// be used to, for instance, populate default data from an asset. Note that
  /// migrations might behave differently when populating the database this way.
  /// For instance, a database created by an [creator] will not receive the
  /// [MigrationStrategy.onCreate] callback because it hasn't been created by
  /// moor.
  FlutterQueryExecutor(
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
  /// moor.
  FlutterQueryExecutor.inDatabaseFolder(
      {required String path,
      bool? logStatements,
      bool singleInstance = true,
      DatabaseCreator? creator})
      : super(
            _SqfliteDelegate(true, path,
                singleInstance: singleInstance, creator: creator),
            logStatements: logStatements);

  /// The underlying sqflite [s.Database] object used by moor to send queries.
  ///
  /// Using the sqflite database can cause unexpected behavior in moor. For
  /// instance, stream queries won't update for updates sent to the [s.Database]
  /// directly.
  /// For this reason, projects shouldn't use this getter unless they absolutely
  /// need to. The database is exposed to make migrating from sqflite to moor
  /// easier.
  ///
  /// Note that this returns null until the moor database has been opened.
  /// A moor database is opened lazily when the first query runs.
  s.Database? get sqfliteDb {
    final sqfliteDelegate = delegate as _SqfliteDelegate;
    return sqfliteDelegate.isOpen ? sqfliteDelegate.db : null;
  }

  @override
  // We're not really required to be sequential since sqflite has an internal
  // lock to bring statements into a sequential order.
  // Setting isSequential here helps with moor cancellations in stream queries
  // though.
  bool get isSequential => true;
}
