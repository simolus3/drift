import 'dart:async';

import 'package:drift/backends.dart';
import 'package:drift/drift.dart';

/// Signature of a function that opens a database connection when instructed to.
typedef DatabaseOpener = FutureOr<QueryExecutor> Function();

/// A special database executor that delegates work to another [QueryExecutor].
/// The other executor is lazily opened by a [DatabaseOpener].
class LazyDatabase extends QueryExecutor {
  late QueryExecutor _delegate;
  bool _delegateAvailable = false;

  Completer<void>? _openDelegate;

  /// The function that will open the database when this [LazyDatabase] gets
  /// opened for the first time.
  final DatabaseOpener opener;

  /// Declares a [LazyDatabase] that will run [opener] when the database is
  /// first requested to be opened.
  LazyDatabase(this.opener);

  Future<void> _awaitOpened() {
    if (_delegateAvailable) {
      return Future.value();
    } else if (_openDelegate != null) {
      return _openDelegate!.future;
    } else {
      final delegate = _openDelegate = Completer();
      Future.sync(opener).then((database) {
        _delegate = database;
        _delegateAvailable = true;
        delegate.complete();
      }, onError: delegate.completeError);
      return delegate.future;
    }
  }

  @override
  TransactionExecutor beginTransaction() => _delegate.beginTransaction();

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) {
    return _awaitOpened().then((_) => _delegate.ensureOpen(user));
  }

  @override
  Future<void> runBatched(BatchedStatements statements) =>
      _delegate.runBatched(statements);

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) =>
      _delegate.runCustom(statement, args);

  @override
  Future<int> runDelete(String statement, List<Object?> args) =>
      _delegate.runDelete(statement, args);

  @override
  Future<int> runInsert(String statement, List<Object?> args) =>
      _delegate.runInsert(statement, args);

  @override
  Future<List<Map<String, Object?>>> runSelect(
      String statement, List<Object?> args) {
    return _delegate.runSelect(statement, args);
  }

  @override
  Future<int> runUpdate(String statement, List<Object?> args) =>
      _delegate.runUpdate(statement, args);

  @override
  Future<void> close() {
    if (_delegateAvailable) {
      return _delegate.close();
    } else {
      return Future.value();
    }
  }
}
