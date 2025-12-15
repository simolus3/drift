import 'connection.dart';
import 'connection_compat.dart';
import 'result_set.dart';

/// An interceptor for SQL queries.
///
/// This wraps an existing [DriftSession] implemented by drift, and by default
/// does nothing. However, specific methods can be overriden to customize the
/// behavior of an existing database session implementation.
///
/// To apply an interceptor to a session, use [ApplyInterceptor.interceptWith].
/// This returns a new [DriftSession] which can be used as a replacement when
/// opening the database.
///
/// For an example on how interceptors may be used and installed, see this
/// documentation page: https://drift.simonbinder.eu/docs/examples/tracing/
abstract base class QueryInterceptor {
  /// Intercept [DriftSession.execute] calls.
  Future<QueryResult> execute(DriftSession session, StatementInfo statement) {
    return session.execute(statement);
  }

  /// Intercept [DriftSession.executeBatch] calls.
  Future<List<QueryResult>> executeBatch(
    DriftSession session,
    StatementBatch batch,
  ) {
    return session.executeBatch(batch);
  }

  /// Intercept [DriftSession.close] calls.
  Future<void> close(DriftSession session) => session.close();

  /// Intercept [DriftTransactionParent.begin] calls.
  Future<DriftSession> begin(
    DriftTransactionParent parent,
    TransactionOptions options,
  ) {
    return parent.begin(options);
  }

  /// Intercept [DriftTransactionSession.commit] calls.
  Future<void> commit(DriftTransactionSession transaction) {
    return transaction.commit();
  }

  /// Intercept [DriftTransactionSession.rollback] calls.
  Future<void> rollback(DriftTransactionSession transaction) {
    return transaction.rollback();
  }

  /// Intercept [DriftRootSession.schemaVersion] calls.
  Future<int> getSchemaVersion(PersistentSchemaVersion session) {
    return session.schemaVersion;
  }

  /// Intercept [DriftRootSession.writeSchemaVersion] calls.
  Future<void> writeSchemaVersion(
    PersistentSchemaVersion session,
    int version,
  ) {
    return session.writeSchemaVersion(version);
  }
}

/// Extension to wrap a [DriftSession] with a [QueryInterceptor].
extension ApplyInterceptor on DriftSession {
  /// Returns a [DriftSession] that will use `this` executor internally, but
  /// with calls intercepted by the given [interceptor].
  ///
  /// This can be used to, for instance, write a custom statement logger or to
  /// retry failing statements automatically.
  DriftSession interceptWith(QueryInterceptor interceptor) {
    return _InterceptedSession(this, interceptor);
  }
}

/// Extension to wrap a [DriftConnection] with a [QueryInterceptor].
extension ApplyInterceptorConnection on DriftConnection {
  /// Returns a [DriftConnection] that will use the same stream queries as
  /// `this`, but replaces its executor by wrapping it with the [interceptor].
  ///
  /// See also: [ApplyInterceptor.interceptWith].
  DriftConnection interceptWith(QueryInterceptor interceptor) {
    return changeSession((old) {
      // When intercepting an entire connection, prefer to wrap the inner
      // session in a compat session so that e.g. calls to create transactions
      // can be intercepted as begin / commit invocations.
      // Since the outermost transaction is always wrapped in a compatibility
      // session and most native session implementations don't support
      // transactions, the interceptor would otherwise see [execute] calls to
      // `BEGIN` instead of a transaction.
      return DriftCompatibilitySession(
        inner: old,
        dialect: dialect,
      ).interceptWith(interceptor);
    });
  }
}

final class _InterceptedSession
    implements
        DriftSession,
        DriftTransactionParent,
        DriftTransactionSession,
        PersistentSchemaVersion,
        DriftSessionWithInternalLocks {
  final DriftSession _original;
  final QueryInterceptor _interceptor;

  _InterceptedSession(this._original, this._interceptor);

  @override
  Future<void> close() => _interceptor.close(_original);

  @override
  Future<void> get closed => _original.closed;

  @override
  Future<QueryResult> execute(StatementInfo statement) {
    return _interceptor.execute(_original, statement);
  }

  @override
  Future<List<QueryResult>> executeBatch(StatementBatch batch) {
    return _interceptor.executeBatch(_original, batch);
  }

  @override
  bool get isClosed => _original.isClosed;

  @override
  DriftSessionWithInternalLocks? get locks {
    return _original.locks == null ? null : this;
  }

  @override
  PersistentSchemaVersion? get persistentSchemaVersion {
    return _original.persistentSchemaVersion == null ? null : this;
  }

  @override
  Object? get tag => _original.tag;

  @override
  DriftTransactionSession? get transaction {
    return _original.transaction == null ? null : this;
  }

  @override
  DriftTransactionParent? get transactionParent {
    return _original.transactionParent == null ? null : this;
  }

  @override
  Future<DriftSession> begin(TransactionOptions options) async {
    return _InterceptedSession(
      await _interceptor.begin(_original.transactionParent!, options),
      _interceptor,
    );
  }

  @override
  Future<void> commit() {
    return _interceptor.commit(_original.transaction!);
  }

  @override
  Future<void> rollback() {
    return _interceptor.rollback(_original.transaction!);
  }

  @override
  Future<int> get schemaVersion {
    return _interceptor.getSchemaVersion(_original.persistentSchemaVersion!);
  }

  @override
  Future<void> writeSchemaVersion(int version) {
    return _interceptor.writeSchemaVersion(
      _original.persistentSchemaVersion!,
      version,
    );
  }

  @override
  Future<DriftSession> exclusive() async {
    return _InterceptedSession(
      await _original.locks!.exclusive(),
      _interceptor,
    );
  }
}
