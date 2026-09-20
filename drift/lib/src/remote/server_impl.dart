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

  final Map<int, QueryExecutor> _managedExecutors = {};

  /// The channel that opened each transaction or exclusive executor.
  ///
  /// A client can disappear without closing its transactions - a browser
  /// tab being closed sends no rollback and no close message. Knowing who
  /// opened an executor lets us end it when that client is gone.
  final Map<int, DriftCommunication> _executorOwners = {};
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
    return comm.closed.then((_) {
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
        () => _runQuery(
          payload.method,
          payload.sql,
          payload.args,
          payload.executorId,
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
      return _transactionControl(comms, payload.control, payload.executorId);
    } else if (payload is RequestCancellation) {
      _cancellableOperations[payload.originalRequestId]?.cancel();
      return null;
    }

    return null;
  }

  Future<ResponsePayload> _handleEnsureOpen(
    DriftCommunication comms,
    EnsureOpen open,
  ) async {
    final executor = await _loadExecutor(open.executorId);
    _knownSchemaVersion = open.schemaVersion;

    return PrimitiveResponsePayload.bool(
      await executor.ensureOpen(_ServerDbUser(this, comms, open.schemaVersion)),
    );
  }

  Future<ResponsePayload?> _runQuery(
    StatementMethod method,
    String sql,
    List<Object?> args,
    int? transactionId,
  ) async {
    final executor = await _loadExecutor(transactionId);

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
    final executor = await _loadExecutor(transactionId);
    await executor.runBatched(stmts);
    return null;
  }

  Future<QueryExecutor> _loadExecutor(int? transactionId) async {
    await _waitForTurn(transactionId);
    if (transactionId == null) return connection;

    final executor = _managedExecutors[transactionId];
    if (executor == null) {
      throw StateError(
        'Executor $transactionId is no longer active: it was committed, '
        'rolled back, or abandoned because the client that opened it was '
        'closed.',
      );
    }
    return executor;
  }

  Future<int> _spawnTransaction(DriftCommunication comm, int? executor) async {
    final transaction = (await _loadExecutor(executor)).beginTransaction();
    await transaction.ensureOpen(
      _ServerDbUser(this, comm, _knownSchemaVersion),
    );
    return _putOwnedExecutor(transaction, comm);
  }

  Future<int> _spawnExclusive(DriftCommunication comm, int? executor) async {
    final exclusive = (await _loadExecutor(executor)).beginExclusive();
    await exclusive.ensureOpen(_ServerDbUser(this, comm, _knownSchemaVersion));
    return _putOwnedExecutor(exclusive, comm);
  }

  int _putExecutor(QueryExecutor executor, {bool beforeCurrent = false}) {
    final id = _currentExecutorId++;
    _managedExecutors[id] = executor;

    if (beforeCurrent && _executorBacklog.isNotEmpty) {
      _executorBacklog.insert(0, id);
    } else {
      _executorBacklog.add(id);
    }

    return id;
  }

  int _putOwnedExecutor(QueryExecutor executor, DriftCommunication owner) {
    final id = _putExecutor(executor, beforeCurrent: true);
    _executorOwners[id] = owner;
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
  ) async {
    if (action == NestedExecutorControl.beginTransaction) {
      return PrimitiveResponsePayload.int(
        await _spawnTransaction(comm, executorId),
      );
    } else if (action == NestedExecutorControl.startExclusive) {
      return PrimitiveResponsePayload.int(
        await _spawnExclusive(comm, executorId),
      );
    }

    final executor = await _loadExecutor(executorId);
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
  /// closed, otherwise leaves its executor at the head of the backlog. Every
  /// other client of this server then waits behind it indefinitely.
  Future<void> _abandonExecutorsOf(DriftCommunication comm) async {
    final owned = [
      for (final MapEntry(:key, :value) in _executorOwners.entries)
        if (value == comm) key,
    ];
    // A nested executor is created after its parent and has to end first.
    owned.sort((a, b) => b.compareTo(a));
    for (final id in owned) {
      await _abandonExecutor(id);
    }
  }

  Future<void> _abandonExecutor(int id) async {
    if (!_managedExecutors.containsKey(id)) return;
    await _waitForTurn(id);
    final executor = _managedExecutors[id];
    if (executor == null) return;

    try {
      if (executor is TransactionExecutor) {
        await executor.rollback();
      } else {
        await executor.close();
      }
    } catch (_) {
      // There is no client left to report this to, and the executor is
      // released either way - drift already considers a transaction over
      // after a rollback, successful or not.
    } finally {
      _releaseExecutor(id);
    }
  }

  void _releaseExecutor(int id) {
    _managedExecutors.remove(id);
    _executorOwners.remove(id);
    _executorBacklog.remove(id);
    _notifyActiveExecutorUpdated();
  }

  Future<void> _waitForTurn(int? transactionId) {
    bool idIsActive() {
      if (transactionId == null) {
        return _executorBacklog.isEmpty;
      } else {
        // A released executor never becomes active again. Reporting it as
        // active makes the caller fail on it instead of waiting forever.
        return !_managedExecutors.containsKey(transactionId) ||
            (_executorBacklog.isNotEmpty &&
                _executorBacklog.first == transactionId);
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
    final id = _server._putExecutor(executor, beforeCurrent: true);
    try {
      await connection.request<void>(RunBeforeOpen(details, id));
    } finally {
      _server._releaseExecutor(id);
    }
  }
}
