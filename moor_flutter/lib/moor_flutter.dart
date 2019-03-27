/// Flutter implementation for the moor database. This library merely provides
/// a thin level of abstraction between the
/// [sqflite](https://pub.dartlang.org/packages/sqflite) library and
/// [moor](https://github.com/simolus3/moor)
library moor_flutter;

import 'dart:async';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:moor/moor.dart';
import 'package:sqflite/sqflite.dart' as s;

export 'package:moor_flutter/src/animated_list.dart';
export 'package:moor/moor.dart';

abstract class _DatabaseOwner extends QueryExecutor {
  _DatabaseOwner(this.logStatements);

  @visibleForOverriding
  s.DatabaseExecutor get db;

  final bool logStatements;

  void _log(String sql, List args) {
    if (logStatements == true) {
      final formattedArgs = (args?.isEmpty ?? true) ? ' no variables' : args;
      print('moor: $sql with $formattedArgs');
    }
  }

  @override
  Future<int> runDelete(String statement, List args) {
    _log(statement, args);
    return db.rawDelete(statement, args);
  }

  @override
  Future<int> runInsert(String statement, List args) {
    _log(statement, args);
    return db.rawInsert(statement, args);
  }

  @override
  Future<List<Map<String, dynamic>>> runSelect(String statement, List args) {
    _log(statement, args);
    return db.rawQuery(statement, args);
  }

  @override
  Future<int> runUpdate(String statement, List args) {
    _log(statement, args);
    return db.rawUpdate(statement, args);
  }

  @override
  Future<void> runCustom(String statement) {
    _log(statement, null);
    return db.execute(statement);
  }
}

/// A query executor that uses sqflite internally.
class FlutterQueryExecutor extends _DatabaseOwner {
  final bool _inDbPath;
  final String path;

  @override
  s.Database db;
  bool _hadMigration = false;

  FlutterQueryExecutor({@required this.path, bool logStatements})
      : _inDbPath = false,
        super(logStatements);

  FlutterQueryExecutor.inDatabaseFolder(
      {@required this.path, bool logStatements})
      : _inDbPath = true,
        super(logStatements);

  @override
  Future<bool> ensureOpen() async {
    if (db != null && db.isOpen) {
      return true;
    }

    String resolvedPath;
    if (_inDbPath) {
      resolvedPath = join(await s.getDatabasesPath(), path);
    } else {
      resolvedPath = path;
    }

    db = await s.openDatabase(resolvedPath, version: databaseInfo.schemaVersion,
        onCreate: (db, version) {
      _hadMigration = true;
      return databaseInfo.handleDatabaseCreation(
        executor: (sql) => db.execute(sql),
      );
    }, onUpgrade: (db, from, to) {
      _hadMigration = true;
      return databaseInfo.handleDatabaseVersionChange(
          executor: (sql) => db.execute(sql), from: from, to: to);
    }, onOpen: (db) async {
      db = db;
      // the openDatabase future will resolve later, so we can get an instance
      // where we can send the queries from the onFinished operation;
      final fn = databaseInfo.migration.onFinished;
      if (fn != null && _hadMigration) {
        await fn();
      }
    });

    return true;
  }

  @override
  TransactionExecutor beginTransaction() {
    return _SqfliteTransactionExecutor.startFromDb(this);
  }
}

class _SqfliteTransactionExecutor extends _DatabaseOwner
    implements TransactionExecutor {
  @override
  s.Transaction db;

  /// This future should complete with the transaction once the transaction has
  /// been created.
  final Future<s.Transaction> _open;
  // This completer will complete when send() is called. We use it because
  // sqflite expects a future in the db.transaction() method. The transaction
  // will be executed when that future completes.
  final Completer _actionCompleter;

  /// This future should complete when the call to db.transaction completes.
  final Future _sendFuture;

  _SqfliteTransactionExecutor(
      this._open, this._actionCompleter, this._sendFuture, bool logStatements)
      : super(logStatements) {
    _open.then((transaction) => db = transaction);
  }

  factory _SqfliteTransactionExecutor.startFromDb(FlutterQueryExecutor db) {
    final actionCompleter = Completer();
    final openingCompleter = Completer<s.Transaction>();

    final sendFuture = db.db.transaction((t) {
      openingCompleter.complete(t);
      return actionCompleter.future;
    });

    return _SqfliteTransactionExecutor(
        openingCompleter.future, actionCompleter, sendFuture, db.logStatements);
  }

  @override
  TransactionExecutor beginTransaction() {
    throw StateError('Transactions cannot create another transaction!');
  }

  @override
  Future<bool> ensureOpen() => _open.then((_) => true);

  @override
  Future<void> send() {
    _actionCompleter.complete(null);
    return _sendFuture;
  }
}
