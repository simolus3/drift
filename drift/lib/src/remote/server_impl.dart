import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/remote.dart';
import 'package:meta/meta.dart';
import 'package:stream_channel/stream_channel.dart';

import '../runtime/cancellation_zone.dart';
import 'communication.dart';
import 'protocol.dart';

/// The implementation of a drift server, managing remote channels to send
/// database requests.
@internal
class ServerImplementation implements DriftServer {
  /// The Underlying database connection that will be used.
  final QueryExecutor connection;

  /// Whether clients are allowed to shutdown this server for all.
  final bool allowRemoteShutdown;

  /// Whether this server should close the executor after shutting down.
  final bool closeExecutorWhenShutdown;

  final Map<int, _ManagedExecutor> _managedExecutors = {};

  int _currentExecutorId = 0;
  int _knownSchemaVersion = 0;

  final Map<int, CancellationToken> _cancellableOperations = {};

  /// when a transaction is active, all queries that don't operate on another
  /// query executor have to wait!
  ///
  /// When this list is empty, the top-level executor is active. When not, the
  /// first transaction id in the backlog is active at the moment. Whenever a
  /// transaction completes, we emit an item on [_backlogUpdated]. This can be
  /// used to implement a lock.
  final List<int> _executorBacklog = [];
  final StreamController<void> _backlogUpdated = StreamController.broadcast(
    sync: true,
  );

  bool _isShuttingDown = false;
  final Set<DriftCommunication> _activeChannels = {};
  final Completer<void> _done = Completer();

  final StreamController<NotifyTablesUpdated> _tableUpdateNotifications =
      StreamController();

  /// Creates a server from the underlying connection and further options.
  ServerImplementation(
    this.connection,
    this.allowRemoteShutdown,
    this.closeExecutorWhenShutdown,
  ) {
    done.then((_) {
      _closeRemainingConnections();
      _tableUpdateNotifications.close();
    });
  }

  @override
  Future<void> get done => _done.future;

  @override
  Stream<NotifyTablesUpdated> get tableUpdateNotifications {
    return _tableUpdateNotifications.stream;
  }

  @override
  Future<void> serve(StreamChannel<Object?> channel, {bool serialize = true}) {
    if (_isShuttingDown) {
      throw StateError('Cannot add new channels after shutdown() was called');
    }

    final comm = DriftCommunication(channel, serialize: serialize);
    comm.setRequestHandler((request) => _handleRequest(comm, request));
    comm.notify(ServerInfo(connection.dialect));

    _activeChannels.add(comm);
    return comm.closed.whenComplete(() {
      _activeChannels.remove(comm);
      return _abandonExecutorsOf(comm);
    });
  }

  @override
  Future<void> shutdown() {
    if (!_isShuttingDown) {
      _isShuttingDown = true;
      _done.complete(closeExecutorWhenShutdown ? connection.close() : null);
    }

    return done;
  }

  void _closeRemainingConnections() {
    for (final channel in _activeChannels) {
      channel.close();
    }
  }

  FutureOr<ResponsePayload?> _handleRequest(
    DriftCommunication comms,
    Request request,
  ) {
    final payload = request.payload;

    if (payload is NoArgsRequest) {
      switch (payload) {
        case NoArgsRequest.terminateAll:
          if (allowRemoteShutdown) {
            _backlogUpdated.close();
            shutdown();
          } else {
            throw StateError('Remote shutdowns not allowed');
          }

          break;
      }
    } else if (payload is EnsureOpen) {
      return _handleEnsureOpen(comms, payload);
    } else if (payload is ExecuteQuery) {
      final token = runCancellable(
        () => _useExecutor(
          payload.executorId,
          (executor) =>
              _runQuery(payload.method, payload.sql, payload.args, executor),
        ),
      );
      _cancellableOperations[request.id] = token;
      return token.result.whenComplete(
        () => _cancellableOperations.remove(request.id),
      );
    } else if (payload is ExecuteBatchedStatement) {
      return _runBatched(payload.stmts, payload.executorId);
    } else if (payload is NotifyTablesUpdated) {
      _tableUpdateNotifications.add(payload);
      dispatchTableUpdateNotification(payload, comms);
    } else if (payload is RunNestedExecutorControl) {
      return _useExecutor(
        payload.executorId,
        (ex) =>
            _transactionControl(comms, payload.control, payload.executorId, ex),
      );
    } else if (payload is RequestCancellation) {
      _cancellableOperations[payload.originalRequestId]?.cancel();
      return null;
    }

    return null;
  }

  Future<ResponsePayload> _handleEnsureOpen(
    DriftCommunication comms,
    EnsureOpen open,
  ) {
    return _useExecutor(open.executorId, (executor) async {
      _knownSchemaVersion = open.schemaVersion;

      return PrimitiveResponsePayload.bool(
        await executor.ensureOpen(
          _ServerDbUser(this, comms, open.schemaVersion),
        ),
      );
    });
  }

  Future<ResponsePayload?> _runQuery(
    StatementMethod method,
    String sql,
    List<Object?> args,
    QueryExecutor executor,
  ) async {
    // Give cancellations more time to come in
    await Future<void>.delayed(Duration.zero);
    checkIfCancelled();

    switch (method) {
      case StatementMethod.custom:
        await executor.runCustom(sql, args);
        return null;
      case StatementMethod.deleteOrUpdate:
        return PrimitiveResponsePayload.int(
          await executor.runDelete(sql, args),
        );
      case StatementMethod.insert:
        return PrimitiveResponsePayload.int(
          await executor.runInsert(sql, args),
        );
      case StatementMethod.select:
        return SelectResult(await executor.runSelect(sql, args));
    }
  }

  Future<ResponsePayload?> _runBatched(
    BatchedStatements stmts,
    int? transactionId,
  ) async {
    await _useExecutor(transactionId, (tx) => tx.runBatched(stmts));
    return null;
  }

  Future<T> _useExecutor<T>(
    int? executorId,
    Future<T> Function(QueryExecutor executor) block,
  ) {
    if (executorId != null) {
      final managed = _managedExecutors[executorId]!;
      if (managed.owner.isClosed) {
        throw StateError('Owner closed');
      }

      final closeGuard = Completer<void>();
      managed.closeGuards.add(closeGuard.future);

      return _waitForTurn(
        executorId,
      ).then((_) => block(managed.executor)).whenComplete(() {
        managed.closeGuards.remove(closeGuard.future);
        closeGuard.complete();
      });
    } else {
      return _waitForTurn(null).then((_) => block(connection));
    }
  }

  Future<int> _spawnTransaction(
    DriftCommunication comm,
    QueryExecutor ex,
  ) async {
    final tx = ex.beginTransaction();
    await tx.ensureOpen(_ServerDbUser(this, comm, _knownSchemaVersion));

    return _putOwnedExecutor(tx, comm);
  }

  Future<int> _spawnExclusive(DriftCommunication comm, QueryExecutor ex) async {
    final exclusive = ex.beginExclusive();
    await exclusive.ensureOpen(_ServerDbUser(this, comm, _knownSchemaVersion));

    return _putOwnedExecutor(exclusive, comm);
  }

  int _putExecutor(
    QueryExecutor executor,
    DriftCommunication owner, {
    bool beforeCurrent = false,
  }) {
    final id = _currentExecutorId++;
    _managedExecutors[id] = _ManagedExecutor(executor, owner);

    if (beforeCurrent && _executorBacklog.isNotEmpty) {
      _executorBacklog.insert(0, id);
    } else {
      _executorBacklog.add(id);
    }

    return id;
  }

  int _putOwnedExecutor(QueryExecutor executor, DriftCommunication owner) {
    final id = _putExecutor(executor, owner, beforeCurrent: true);
    if (owner.isClosed) {
      // The client went away while this executor was waiting for its turn,
      // so nothing will ever commit it or roll it back.
      unawaited(_abandonExecutor(id));
    }
    return id;
  }

  Future<ResponsePayload?> _transactionControl(
    DriftCommunication comm,
    NestedExecutorControl action,
    int? executorId,
    QueryExecutor executor,
  ) async {
    if (action == NestedExecutorControl.beginTransaction) {
      return PrimitiveResponsePayload.int(
        await _spawnTransaction(comm, executor),
      );
    } else if (action == NestedExecutorControl.startExclusive) {
      return PrimitiveResponsePayload.int(
        await _spawnExclusive(comm, executor),
      );
    }

    if (action == NestedExecutorControl.endExclusive) {
      await executor.close();
      _releaseExecutor(executorId!);
      return null;
    }

    if (executor is! TransactionExecutor) {
      throw ArgumentError.value(
        executorId,
        'transactionId',
        "Does not reference a transaction. This might happen if you don't "
            'await all operations made inside a transaction, in which case the '
            'transaction might complete with pending operations.',
      );
    }

    switch (action) {
      case NestedExecutorControl.commit:
        await executor.send();
        // The transaction should only be released if the commit doesn't throw.
        _releaseExecutor(executorId!);
        break;
      case NestedExecutorControl.rollback:
        // Rollbacks shouldn't fail. Other parts of drift assume the transaction
        // to be over after a rollback either way, so we always release the
        // executor in this case.
        try {
          await executor.rollback();
        } finally {
          _releaseExecutor(executorId!);
        }
        break;
      default:
        assert(false, 'Unknown TransactionControl');
    }

    return null;
  }

  /// Rolls back the transactions and closes the exclusive executors [comm]
  /// opened and can no longer finish because it closed.
  ///
  /// A client that disappears mid-transaction, like a browser tab that is
  /// closed, otherwise leaves its executor at the head of the backlog.
  Future<void> _abandonExecutorsOf(DriftCommunication comm) async {
    await Future.wait([
      for (final MapEntry(:key, :value) in _managedExecutors.entries)
        if (value.owner == comm) _abandonExecutor(key),
    ]);
  }

  Future<void> _abandonExecutor(int id) async {
    final executor = _managedExecutors[id];
    if (executor == null) return;

    await _waitForTurn(id);
    // Statements that already hold this executor finish first: rolling back
    // underneath one would let it run outside its transaction.
    while (executor.closeGuards.isNotEmpty) {
      await executor.closeGuards.first;
    }

    try {
      await switch (executor.executor) {
        final TransactionExecutor tx => tx.rollback(),
        final other => other.close(),
      };
    } finally {
      _releaseExecutor(id);
    }
  }

  void _releaseExecutor(int id) {
    _managedExecutors.remove(id);
    _executorBacklog.remove(id);
    _notifyActiveExecutorUpdated();
  }

  Future<void> _waitForTurn(int? transactionId) {
    bool idIsActive() {
      if (transactionId == null) {
        return _executorBacklog.isEmpty;
      } else {
        return _executorBacklog.isNotEmpty &&
            _executorBacklog.first == transactionId;
      }
    }

    // Don't wait for a backlog update if the current transaction id is active
    if (idIsActive()) return Future.value(null);

    return _backlogUpdated.stream.firstWhere((_) => idIsActive());
  }

  void _notifyActiveExecutorUpdated() {
    if (!_backlogUpdated.isClosed) {
      _backlogUpdated.add(null);
    }
  }

  @override
  void dispatchTableUpdateNotification(
    NotifyTablesUpdated notification, [
    DriftCommunication? source,
  ]) {
    for (final connected in _activeChannels) {
      if (connected != source) {
        connected.notify(notification);
      }
    }
  }
}

/// A managed executor and the channel that opened it.
///
/// A client can disappear without closing its transactions - a closed browser
/// tab sends no rollback and no close message - so the server has to know who
/// opened an executor to end it when that client is gone. [owner] is null for
/// the executors the server itself puts up, such as the one a `beforeOpen`
/// callback runs on.
final class _ManagedExecutor {
  final QueryExecutor executor;
  final DriftCommunication owner;

  final Set<Future<void>> closeGuards = {};

  _ManagedExecutor(this.executor, this.owner);
}

class _ServerDbUser implements QueryExecutorUser {
  final ServerImplementation _server;
  final DriftCommunication connection;
  @override
  final int schemaVersion;

  _ServerDbUser(this._server, this.connection, this.schemaVersion);

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {
    final id = _server._putExecutor(executor, connection, beforeCurrent: true);
    try {
      await connection.request<void>(RunBeforeOpen(details, id));
    } finally {
      _server._releaseExecutor(id);
    }
  }
}
