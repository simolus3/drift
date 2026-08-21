/// @docImport 'worker.dart';
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:drift3_preview/drift.dart';
import 'package:meta/meta.dart';
import 'package:sqlite3_web/protocol_utils.dart' as utils;
import 'package:sqlite3_web/sqlite3_web.dart';

import '../shared.dart';
import 'protocol.dart';

abstract base class _BaseWebSession implements DriftSession {
  final Database database;
  final LockToken? lockToken;
  final bool requireInTransaction;

  _BaseWebSession(
    this.database, {
    this.lockToken,
    this.requireInTransaction = false,
  });

  @override
  Future<QueryResult> execute(StatementInfo statement) async {
    final (params, paramTypes) = utils.serializeParameters(
      statement.variables.map((p) => p.rawValue).toList(),
    );

    final response = await database
        .customRequest(
          ExecuteRequest(
            sql: statement.sql,
            needsResultSet: statement.needsResultSet,
            parameters: params,
            parameterTypes: paramTypes,
            requireInTransaction: requireInTransaction,
            type: BaseRequest.typeExecute,
          ),
          token: lockToken,
        )
        .translateExceptions();

    return (response as SerializedQueryResult).asQueryResult();
  }

  @override
  Future<List<QueryResult>> executeBatch(StatementBatch batch) async {
    final sql = batch.sql.map((e) => e.toJS).toList().toJS;
    final entries = JSArray<ExecuteBatchEntry>.withLength(
      batch.statements.length,
    );
    for (final (i, stmt) in batch.statements.indexed) {
      final (parameters, parameterTypes) = utils.serializeParameters(
        stmt.info.variables.map((p) => p.rawValue).toList(),
      );

      entries[i] = ExecuteBatchEntry(
        sqlIndex: stmt.sqlIndex,
        parameters: parameters,
        parameterTypes: parameterTypes,
        needsResultSet: stmt.info.needsResultSet,
      );
    }

    final response = await database
        .customRequest(
          ExecuteBatchRequest(
            sql: sql,
            entries: entries,
            requireInTransaction: requireInTransaction,
            type: BaseRequest.typeExecuteBatch,
          ),
          token: lockToken,
        )
        .translateExceptions();

    final results = response as JSArray<SerializedQueryResult>;
    return results.toDart.map((e) => e.asQueryResult()).toList();
  }

  @override
  Object? get tag => null;
}

/// A drift session implementation based on the `sqlite3_web` package.
final class WebSession extends _BaseWebSession
    implements DriftSessionWithInternalLocks, DriftTransactionParent {
  @override
  late final Future<void> closed;
  @override
  bool isClosed = false;

  final List<_InnerSession> _activeInnerSessions = [];

  /// Wraps a [Database] from the `sqlite3_web` package as a [DriftSession]
  /// implementation.
  ///
  /// The database must be backed by a [DriftWorkerDatabase].
  WebSession(super.database) {
    closed = database.closed.whenComplete(() {
      // Mark all inner sessions as closed.
      for (final inner in _activeInnerSessions) {
        inner._isClosed.complete();
      }

      isClosed = true;
    });
  }

  @override
  Future<void> close() async {
    await database.dispose();
    await closed;
  }

  @override
  DriftSessionWithInternalLocks? get locks => this;

  @override
  PersistentSchemaVersion? get persistentSchemaVersion =>
      PragmaPersistedSchemaVersion(this);

  @override
  DriftTransactionSession? get transaction => null;

  @override
  DriftTransactionParent? get transactionParent => this;

  @override
  Future<DriftSession> exclusive() {
    final completer = Completer<DriftSession>.sync();
    database
        .requestLock<void>((token) {
          final session = _ExclusiveSession(this, token);
          completer.complete(session);

          return session.closed;
        }, abortTrigger: cancellationSignal)
        .translateExceptions()
        .onError((Object error, StackTrace trace) {
          if (!completer.isCompleted) completer.completeError(error, trace);
        });
    return completer.future;
  }

  @override
  Future<DriftSession> begin(TransactionOptions options) {
    final completer = Completer<DriftSession>.sync();
    database
        .requestLock<void>((token) async {
          final session = _TransactionSession(this, token);
          await database.execute('BEGIN', token: token);
          completer.complete(session);

          return await session.closed;
        }, abortTrigger: cancellationSignal)
        .translateExceptions()
        .onError((Object error, StackTrace trace) {
          if (!completer.isCompleted) completer.completeError(error, trace);
        });
    return completer.future;
  }
}

abstract base class _InnerSession extends _BaseWebSession {
  final Completer<void> _isClosed = Completer();
  final WebSession _parent;

  _InnerSession(this._parent, LockToken lockToken, {super.requireInTransaction})
    : super(_parent.database, lockToken: lockToken) {
    _parent._activeInnerSessions.add(this);
  }

  @override
  Future<void> get closed => _isClosed.future;

  @override
  bool get isClosed => _isClosed.isCompleted;

  @override
  Future<void> close() async {
    if (!_isClosed.isCompleted) {
      _parent._activeInnerSessions.remove(this);
      _isClosed.complete(closeInner());
    }
  }

  @protected
  Future<void> closeInner() async {}

  @override
  DriftSessionWithInternalLocks? get locks => null;

  @override
  PersistentSchemaVersion? get persistentSchemaVersion => null;
}

final class _ExclusiveSession extends _InnerSession {
  _ExclusiveSession(super.parent, super.lockToken);

  @override
  DriftTransactionSession? get transaction => null;

  @override
  DriftTransactionParent? get transactionParent => null;
}

final class _TransactionSession extends _InnerSession
    implements DriftTransactionSession {
  var _didFinish = false;

  _TransactionSession(super.parent, super.lockToken)
    : super(requireInTransaction: true);

  @override
  Future<void> commit() async {
    _didFinish = true;
    await database.execute(
      'COMMIT',
      checkInTransaction: true,
      token: lockToken,
    );
    await close();
  }

  @override
  Future<void> rollback() async {
    _didFinish = true;
    await database.execute(
      'ROLLBACK',
      checkInTransaction: true,
      token: lockToken,
    );
    await close();
  }

  @override
  Future<void> closeInner() async {
    if (!_didFinish) {
      await rollback();
    }
  }

  @override
  DriftTransactionSession? get transaction => this;

  @override
  DriftTransactionParent? get transactionParent => null;
}

extension<T> on Future<T> {
  Future<T> translateExceptions() {
    return onError((Object error, StackTrace trace) {
      if (error is AbortException) {
        Error.throwWithStackTrace(const CancellationException(), trace);
      } else if (error case RemoteException(:final exception?)) {
        Error.throwWithStackTrace(exception, trace);
      }

      throw error;
    });
  }
}
