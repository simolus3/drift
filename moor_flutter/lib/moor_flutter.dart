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

  void _log(String sql, [List args]) {
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

  @override
  Future<void> runBatched(List<BatchedStatement> statements) async {
    final batch = db.batch();

    for (var statement in statements) {
      for (var boundVariables in statement.variables) {
        _log(statement.sql, boundVariables);
        batch.execute(statement.sql, boundVariables);
      }
    }

    await batch.commit(noResult: true);
  }
}

/// A query executor that uses sqflite internally.
class FlutterQueryExecutor extends _DatabaseOwner {
  final bool _inDbPath;
  final String path;

  @override
  s.Database db;
  Completer<void> _openingCompleter;
  bool _hadMigration = false;
  int _versionBefore;

  FlutterQueryExecutor({@required this.path, bool logStatements})
      : _inDbPath = false,
        super(logStatements);

  FlutterQueryExecutor.inDatabaseFolder(
      {@required this.path, bool logStatements})
      : _inDbPath = true,
        super(logStatements);

  @override
  Future<bool> ensureOpen() async {
    // mechanism to ensure that _openDatabase is only called once, even if we
    // have many queries calling ensureOpen() repeatedly. _openingCompleter is
    // set if we're currently in the process of opening the database.
    if (_openingCompleter != null) {
      // already opening, wait for that to finish and don't open the database
      // again
      await _openingCompleter.future;
      return true;
    }
    if (db != null && db.isOpen) {
      // database is opened and ready
      return true;
    }

    // alright, opening the database
    _openingCompleter = Completer();
    await _openDatabase();
    _openingCompleter.complete();

    return true;
  }

  Future _openDatabase() async {
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
        executor: _migrationExecutor(db),
      );
    }, onUpgrade: (db, from, to) {
      _hadMigration = true;
      _versionBefore = from;
      return databaseInfo.handleDatabaseVersionChange(
          executor: _migrationExecutor(db), from: from, to: to);
    }, onOpen: (db) async {
      final versionNow = await db.getVersion();
      final resolvedPrevious = _hadMigration ? _versionBefore : versionNow;
      final details = OpeningDetails(resolvedPrevious, versionNow);

      await databaseInfo.beforeOpenCallback(
          _BeforeOpenExecutor(db, logStatements), details);
    });
  }

  SqlExecutor _migrationExecutor(s.Database db) {
    return (sql) {
      _log(sql);
      return db.execute(sql);
    };
  }

  @override
  TransactionExecutor beginTransaction() {
    return _SqfliteTransactionExecutor.startFromDb(this);
  }
}

class _SqfliteTransactionExecutor extends _DatabaseOwner
    with TransactionExecutor {
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
  Future<bool> ensureOpen() => _open.then((_) => true);

  @override
  Future<void> send() {
    _actionCompleter.complete(null);
    return _sendFuture;
  }
}

class _BeforeOpenExecutor extends _DatabaseOwner with BeforeOpenMixin {
  @override
  final s.DatabaseExecutor db;

  _BeforeOpenExecutor(this.db, bool logStatements) : super(logStatements);
}
