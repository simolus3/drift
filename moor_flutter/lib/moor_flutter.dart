/// Flutter implementation for the moor database. This library merely provides
/// a thin level of abstraction between the
/// [sqflite](https://pub.dartlang.org/packages/sqflite) library and
/// [moor](https://github.com/simolus3/moor)
library moor_flutter;

import 'dart:async';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:moor/moor.dart';
import 'package:moor/backends.dart';
import 'package:sqflite/sqflite.dart' as s;

export 'package:moor_flutter/src/animated_list.dart';
export 'package:moor/moor.dart';

class _SqfliteDelegate extends DatabaseDelegate with _SqfliteExecutor {
  int _loadedSchemaVersion;
  @override
  s.Database db;

  final bool inDbFolder;
  final String path;

  bool singleInstance;

  _SqfliteDelegate(this.inDbFolder, this.path, {this.singleInstance}) {
    singleInstance ??= true;
  }

  @override
  DbVersionDelegate get versionDelegate {
    return OnOpenVersionDelegate(() => Future.value(_loadedSchemaVersion));
  }

  @override
  TransactionDelegate get transactionDelegate =>
      _SqfliteTransactionDelegate(this);

  @override
  Future<bool> get isOpen => Future.value(db != null);

  @override
  Future<void> open([GeneratedDatabase db]) async {
    String resolvedPath;
    if (inDbFolder) {
      resolvedPath = join(await s.getDatabasesPath(), path);
    } else {
      resolvedPath = path;
    }

    // default value when no migration happened
    _loadedSchemaVersion = db.schemaVersion;

    this.db = await s.openDatabase(
      resolvedPath,
      version: db.schemaVersion,
      onCreate: (db, version) {
        _loadedSchemaVersion = 0;
      },
      onUpgrade: (db, from, to) {
        _loadedSchemaVersion = from;
      },
      singleInstance: singleInstance,
    );
  }

  @override
  Future<void> close() {
    return db.close();
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
      // Ignore the errr! We send a fake exception to indicate a rollback.
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
  Future<void> runBatched(List<BatchedStatement> statements) async {
    final batch = db.batch();

    for (var statement in statements) {
      for (var boundVariables in statement.variables) {
        batch.execute(statement.sql, boundVariables);
      }
    }

    await batch.commit(noResult: true);
  }

  @override
  Future<void> runCustom(String statement, List args) {
    return db.execute(statement);
  }

  @override
  Future<int> runInsert(String statement, List args) {
    return db.rawInsert(statement, args);
  }

  @override
  Future<QueryResult> runSelect(String statement, List args) async {
    final result = await db.rawQuery(statement, args);
    return QueryResult.fromRows(result);
  }

  @override
  Future<int> runUpdate(String statement, List args) {
    return db.rawUpdate(statement, args);
  }
}

/// A query executor that uses sqflite internally.
class FlutterQueryExecutor extends DelegatedDatabase {
  /// A query executor that will store the database in the file declared by
  /// [path]. If [logStatements] is true, statements sent to the database will
  /// be [print]ed, which can be handy for debugging. The [singleInstance]
  /// parameter sets the corresponding parameter on [s.openDatabase].
  FlutterQueryExecutor(
      {@required String path, bool logStatements, bool singleInstance})
      : super(_SqfliteDelegate(false, path, singleInstance: singleInstance),
            logStatements: logStatements);

  /// A query executor that will store the database in the file declared by
  /// [path], which will be resolved relative to [s.getDatabasesPath()].
  /// If [logStatements] is true, statements sent to the database will
  /// be [print]ed, which can be handy for debugging. The [singleInstance]
  /// parameter sets the corresponding parameter on [s.openDatabase].
  FlutterQueryExecutor.inDatabaseFolder(
      {@required String path, bool logStatements, bool singleInstance})
      : super(_SqfliteDelegate(true, path, singleInstance: singleInstance),
            logStatements: logStatements);
}
