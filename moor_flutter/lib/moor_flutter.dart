/// Flutter implementation for the moor database. This library merely provides
/// a thin level of abstraction between the
/// [sqflite](https://pub.dartlang.org/packages/sqflite) library and
/// [moor](https://github.com/simolus3/moor)
library moor_flutter;

import 'dart:async';
import 'dart:io';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:moor/moor.dart';
import 'package:moor/backends.dart';
import 'package:sqflite/sqflite.dart' as s;

export 'package:moor_flutter/src/animated_list.dart';
export 'package:moor/moor.dart';

/// Signature of a function that runs when a database doesn't exist on file.
/// This can be useful to, for instance, load the database from an asset if it
/// doesn't exist.
typedef DatabaseCreator = FutureOr<void> Function(File file);

class _SqfliteDelegate extends DatabaseDelegate with _SqfliteExecutor {
  int _loadedSchemaVersion;
  @override
  s.Database db;

  final bool inDbFolder;
  final String path;

  bool singleInstance;
  final DatabaseCreator creator;

  _SqfliteDelegate(this.inDbFolder, this.path,
      {this.singleInstance, this.creator}) {
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
  bool get isOpen => db != null;

  @override
  Future<void> open([GeneratedDatabase db]) async {
    String resolvedPath;
    if (inDbFolder) {
      resolvedPath = join(await s.getDatabasesPath(), path);
    } else {
      resolvedPath = path;
    }

    final file = File(resolvedPath);
    if (creator != null && !await file.exists()) {
      await creator(file);
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
  /// The [creator] will be called when the database file doesn't exist. It can
  /// be used to, for instance, populate default data from an asset. Note that
  /// migrations might behave differently when populating the database this way.
  /// For instance, a database created by an [creator] will not receive the
  /// [MigrationStrategy.onCreate] callback because it hasn't been created by
  /// moor.
  FlutterQueryExecutor(
      {@required String path,
      bool logStatements,
      bool singleInstance,
      DatabaseCreator creator})
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
      {@required String path,
      bool logStatements,
      bool singleInstance,
      DatabaseCreator creator})
      : super(
            _SqfliteDelegate(true, path,
                singleInstance: singleInstance, creator: creator),
            logStatements: logStatements);
}
