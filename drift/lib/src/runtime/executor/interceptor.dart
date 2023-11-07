import '../api/runtime_api.dart';
import '../query_builder/query_builder.dart';
import 'executor.dart';

/// Extension to wrap a [QueryExecutor] with a [QueryInterceptor].
extension ApplyInterceptor on QueryExecutor {
  /// Returns a [QueryExecutor] that will use `this` executor internally, but
  /// with calls intercepted by the given [interceptor].
  ///
  /// This can be used to, for instance, write a custom statement logger or to
  /// retry failing statements automatically.
  QueryExecutor interceptWith(QueryInterceptor interceptor) {
    final $this = this;

    if ($this is TransactionExecutor) {
      return _InterceptedTransactionExecutor($this, interceptor);
    } else {
      return _InterceptedExecutor($this, interceptor);
    }
  }
}

/// Extension to wrap a [DatabaseConnection] with a [QueryInterceptor].
extension ApplyInterceptorConnection on DatabaseConnection {
  /// Returns a [DatabaseConnection] that will use the same stream queries as
  /// `this`, but replaces its executor by wrapping it with the [interceptor].
  ///
  /// See also: [ApplyInterceptor.interceptWith].
  DatabaseConnection interceptWith(QueryInterceptor interceptor) {
    return withExecutor(executor.interceptWith(interceptor));
  }
}

/// An interceptor for SQL queries.
///
/// This wraps an existing [QueryExecutor] implemented by drift, and by default
/// does nothing. However, specific methods can be overridden to customize the
/// behavior of an existing query executor.
abstract class QueryInterceptor {
  /// Intercept [QueryExecutor.dialect] calls.
  SqlDialect dialect(QueryExecutor executor) => executor.dialect;

  /// Intercept [QueryExecutor.beginTransaction] calls.
  TransactionExecutor beginTransaction(QueryExecutor parent) =>
      parent.beginTransaction();

  /// Intercept [TransactionExecutor.supportsNestedTransactions] calls.
  bool transactionCanBeNested(TransactionExecutor inner) {
    return inner.supportsNestedTransactions;
  }

  /// Intercept [QueryExecutor.close] calls.
  Future<void> close(QueryExecutor inner) => inner.close();

  /// Intercept [TransactionExecutor.send] calls.
  Future<void> commitTransaction(TransactionExecutor inner) {
    return inner.send();
  }

  /// Intercept [TransactionExecutor.rollback] calls.
  Future<void> rollbackTransaction(TransactionExecutor inner) {
    return inner.rollback();
  }

  /// Intercept [QueryExecutor.ensureOpen] calls.
  Future<bool> ensureOpen(QueryExecutor executor, QueryExecutorUser user) =>
      executor.ensureOpen(user);

  /// Intercept [QueryExecutor.runBatched] calls.
  Future<void> runBatched(
      QueryExecutor executor, BatchedStatements statements) {
    return executor.runBatched(statements);
  }

  /// Intercept [QueryExecutor.runCustom] calls.
  Future<void> runCustom(
      QueryExecutor executor, String statement, List<Object?> args) {
    return executor.runCustom(statement, args);
  }

  /// Intercept [QueryExecutor.runInsert] calls.
  Future<int> runInsert(
      QueryExecutor executor, String statement, List<Object?> args) {
    return executor.runInsert(statement, args);
  }

  /// Intercept [QueryExecutor.runDelete] calls.
  Future<int> runDelete(
      QueryExecutor executor, String statement, List<Object?> args) {
    return executor.runDelete(statement, args);
  }

  /// Intercept [QueryExecutor.runUpdate] calls.
  Future<int> runUpdate(
      QueryExecutor executor, String statement, List<Object?> args) {
    return executor.runUpdate(statement, args);
  }

  /// Intercept [QueryExecutor.runSelect] calls.
  Future<List<Map<String, Object?>>> runSelect(
      QueryExecutor executor, String statement, List<Object?> args) {
    return executor.runSelect(statement, args);
  }
}

class _InterceptedExecutor extends QueryExecutor {
  final QueryExecutor _inner;
  final QueryInterceptor _interceptor;

  _InterceptedExecutor(this._inner, this._interceptor);

  @override
  TransactionExecutor beginTransaction() => _InterceptedTransactionExecutor(
      _interceptor.beginTransaction(_inner), _interceptor);

  @override
  SqlDialect get dialect => _interceptor.dialect(_inner);

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) {
    return _interceptor.ensureOpen(_inner, user);
  }

  @override
  Future<void> runBatched(BatchedStatements statements) {
    return _interceptor.runBatched(_inner, statements);
  }

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) {
    return _interceptor.runCustom(_inner, statement, args ?? const []);
  }

  @override
  Future<int> runDelete(String statement, List<Object?> args) {
    return _interceptor.runDelete(_inner, statement, args);
  }

  @override
  Future<int> runInsert(String statement, List<Object?> args) {
    return _interceptor.runInsert(_inner, statement, args);
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
      String statement, List<Object?> args) {
    return _interceptor.runSelect(_inner, statement, args);
  }

  @override
  Future<int> runUpdate(String statement, List<Object?> args) {
    return _interceptor.runUpdate(_inner, statement, args);
  }

  @override
  Future<void> close() {
    return _interceptor.close(_inner);
  }
}

class _InterceptedTransactionExecutor extends _InterceptedExecutor
    implements TransactionExecutor {
  _InterceptedTransactionExecutor(super.inner, super.interceptor);

  @override
  Future<void> rollback() {
    return _interceptor.rollbackTransaction(_inner as TransactionExecutor);
  }

  @override
  Future<void> send() {
    return _interceptor.commitTransaction(_inner as TransactionExecutor);
  }

  @override
  bool get supportsNestedTransactions =>
      _interceptor.transactionCanBeNested(_inner as TransactionExecutor);
}
