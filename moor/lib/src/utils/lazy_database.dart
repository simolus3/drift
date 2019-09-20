import 'dart:async';

import 'package:moor/backends.dart';

/// Signature of a function that opens a database connection when instructed to.
typedef DatabaseOpener = FutureOr<QueryExecutor> Function();

/// A special database executor that delegates work to another [QueryExecutor].
/// The other executor is lazily opened by a [DatabaseOpener].
class LazyDatabase extends QueryExecutor {
  QueryExecutor _delegate;
  Completer<void> _openDelegate;

  /// The function that will open the database when this [LazyDatabase] gets
  /// opened for the first time.
  final DatabaseOpener opener;

  LazyDatabase(this.opener);

  Future<void> _awaitOpened() {
    if (_delegate != null) {
      return Future.value();
    } else if (_openDelegate != null) {
      return _openDelegate.future;
    } else {
      _openDelegate = Completer();
      Future.value(opener()).then((database) {
        _delegate = database;
        _openDelegate.complete();
      });
      return _openDelegate.future;
    }
  }

  @override
  TransactionExecutor beginTransaction() => _delegate.beginTransaction();

  @override
  Future<bool> ensureOpen() {
    return _awaitOpened().then((_) => _delegate.ensureOpen());
  }

  @override
  Future<void> runBatched(List<BatchedStatement> statements) =>
      _delegate.runBatched(statements);

  @override
  Future<void> runCustom(String statement, [List args]) =>
      _delegate.runCustom(statement, args);

  @override
  Future<int> runDelete(String statement, List args) =>
      _delegate.runDelete(statement, args);

  @override
  Future<int> runInsert(String statement, List args) =>
      _delegate.runInsert(statement, args);

  @override
  Future<List<Map<String, dynamic>>> runSelect(String statement, List args) =>
      _delegate.runSelect(statement, args);

  @override
  Future<int> runUpdate(String statement, List args) =>
      _delegate.runUpdate(statement, args);
}
