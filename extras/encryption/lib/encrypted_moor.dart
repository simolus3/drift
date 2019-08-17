/// Encryption support for moor, built with the [sqflite_sqlcipher](https://github.com/davidmartos96/sqflite_sqlcipher)
/// library.
library encrypted_moor;

import 'dart:async';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:moor/moor.dart';
import 'package:moor/backends.dart';
import 'package:sqflite/sqflite.dart' as s;

class _SqfliteDelegate extends DatabaseDelegate with _SqfliteExecutor {
  int _loadedSchemaVersion;
  @override
  s.Database db;

  final bool inDbFolder;
  final String path;
  final String password;

  _SqfliteDelegate(this.inDbFolder, this.path, this.password);

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

    // default value when no migration happened
    _loadedSchemaVersion = db.schemaVersion;

    this.db = await s.openDatabase(
      resolvedPath,
      version: db.schemaVersion,
      password: password,
      onCreate: (db, version) {
        _loadedSchemaVersion = 0;
      },
      onUpgrade: (db, from, to) {
        _loadedSchemaVersion = from;
      },
    );
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

/// A query executor that uses sqflite_sqlcipher internally.
class EncryptedExecutor extends DelegatedDatabase {
  EncryptedExecutor(
      {@required String path, @required String password, bool logStatements})
      : super(_SqfliteDelegate(false, path, password),
            logStatements: logStatements);

  EncryptedExecutor.inDatabaseFolder(
      {@required String path, @required String password, bool logStatements})
      : super(_SqfliteDelegate(true, path, password),
            logStatements: logStatements);
}
