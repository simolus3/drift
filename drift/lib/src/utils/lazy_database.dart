import 'dart:async';

import 'package:drift/backends.dart';
import 'package:drift/drift.dart';

/// Signature of a function that opens a database connection when instructed to.
typedef DatabaseOpener = FutureOr<QueryExecutor> Function();

/// A special database executor that delegates work to another [QueryExecutor].
/// The other executor is lazily opened by a [DatabaseOpener].
class LazyDatabase extends QueryExecutor {
  /// Underlying executor
  late final QueryExecutor _delegate;

  bool _delegateAvailable = false;
  final SqlDialect _dialect;

  Completer<void>? _openDelegate;

  @override
  SqlDialect get dialect {
    // Drift reads dialect before database opened, so we must know in advance
    if (_delegateAvailable && _dialect != _delegate.dialect) {
      throw Exception('LazyDatabase created with $_dialect, but underlying '
          'database is ${_delegate.dialect}.');
    }
    return _dialect;
  }

  /// The function that will open the database when this [LazyDatabase] gets
  /// opened for the first time.
  final DatabaseOpener opener;

  /// Declares a [LazyDatabase] that will run [opener] when the database is
  /// first requested to be opened. You must specify the same [dialect] as the
  /// underlying database has
  LazyDatabase(this.opener, {SqlDialect dialect = SqlDialect.sqlite})
      : _dialect = dialect;

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
  QueryExecutor beginExclusive() => _delegate.beginExclusive();

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
