import 'dart:async';

import 'package:moor/moor.dart';
import 'package:moor/remote.dart';
import 'package:stream_channel/stream_channel.dart';

import '../cancellation_zone.dart';
import 'communication.dart';
import 'protocol.dart';

/// The implementation of a moor server, manging remote channels to send
/// database requests.
class ServerImplementation implements MoorServer {
  /// The Underlying database connection that will be used.
  final DatabaseConnection connection;

  /// Whether clients are allowed to shutdown this server for all.
  final bool allowRemoteShutdown;

  final Map<int, QueryExecutor> _managedExecutors = {};
  int _currentExecutorId = 0;

  final Map<int, CancellationToken> _cancellableOperations = {};

  /// when a transaction is active, all queries that don't operate on another
  /// query executor have to wait!
  ///
  /// When this list is empty, the top-level executor is active. When not, the
  /// first transaction id in the backlog is active at the moment. Whenever a
  /// transaction completes, we emit an item on [_backlogUpdated]. This can be
  /// used to implement a lock.
  final List<int> _executorBacklog = [];
  final StreamController<void> _backlogUpdated =
      StreamController.broadcast(sync: true);

  late final _ServerDbUser _dbUser = _ServerDbUser(this);

  bool _isShuttingDown = false;
  final Set<MoorCommunication> _activeChannels = {};
  final Completer<void> _done = Completer();

  /// Creates a server from the underlying connection and further options.
  ServerImplementation(this.connection, this.allowRemoteShutdown);

  @override
  Future<void> get done => _done.future;

  @override
  void serve(StreamChannel<Object?> channel) {
    if (_isShuttingDown) {
      throw StateError('Cannot add new channels after shutdown() was called');
    }

    final comm = MoorCommunication(channel)..setRequestHandler(_handleRequest);
    _activeChannels.add(comm);
    comm.closed.then((_) => _activeChannels.remove(comm));
  }

  @override
  Future<void> shutdown() {
    _isShuttingDown = true;
    return done;
  }

  MoorCommunication? get _anyClient {
    final iterator = _activeChannels.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }

    return null;
  }

  dynamic _handleRequest(Request request) {
    final payload = request.payload;

    if (payload is NoArgsRequest) {
      switch (payload) {
        case NoArgsRequest.getTypeSystem:
          return connection.typeSystem;
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
      return _handleEnsureOpen(payload);
    } else if (payload is ExecuteQuery) {
      final token = runCancellable(() => _runQuery(
          payload.method, payload.sql, payload.args, payload.executorId));
      _cancellableOperations[request.id] = token;
      return token.result
          // If we get a null response the operation was cancelled
          .then((value) => value ?? Future.error(const CancellationException()))
          .whenComplete(() => _cancellableOperations.remove(request.id));
    } else if (payload is ExecuteBatchedStatement) {
      return _runBatched(payload.stmts, payload.executorId);
    } else if (payload is NotifyTablesUpdated) {
      for (final connected in _activeChannels) {
        connected.request(payload);
      }
    } else if (payload is RunTransactionAction) {
      return _transactionControl(payload.control, payload.executorId);
    } else if (payload is RequestCancellation) {
      _cancellableOperations[payload.originalRequestId]?.cancel();
      return null;
    }
  }

  Future<bool> _handleEnsureOpen(EnsureOpen open) async {
    _dbUser.schemaVersion = open.schemaVersion;
    final executor = await _loadExecutor(open.executorId);

    return await executor.ensureOpen(_dbUser);
  }

  Future<dynamic> _runQuery(StatementMethod method, String sql,
      List<Object?> args, int? transactionId) async {
    final executor = await _loadExecutor(transactionId);

    switch (method) {
      case StatementMethod.custom:
        return executor.runCustom(sql, args);
      case StatementMethod.deleteOrUpdate:
        return executor.runDelete(sql, args);
      case StatementMethod.insert:
        return executor.runInsert(sql, args);
      case StatementMethod.select:
        return SelectResult(await executor.runSelect(sql, args));
    }
  }

  Future<void> _runBatched(BatchedStatements stmts, int? transactionId) async {
    final executor = await _loadExecutor(transactionId);
    await executor.runBatched(stmts);
  }

  Future<QueryExecutor> _loadExecutor(int? transactionId) async {
    await _waitForTurn(transactionId);
    return transactionId != null
        ? _managedExecutors[transactionId]!
        : connection.executor;
  }

  Future<int> _spawnTransaction(int? executor) async {
    final transaction = (await _loadExecutor(executor)).beginTransaction();
    final id = _putExecutor(transaction, beforeCurrent: true);

    await transaction.ensureOpen(_dbUser);
    return id;
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

  Future<dynamic> _transactionControl(
      TransactionControl action, int? executorId) async {
    if (action == TransactionControl.begin) {
      return await _spawnTransaction(executorId);
    }

    final executor = _managedExecutors[executorId];
    if (executor is! TransactionExecutor) {
      throw ArgumentError.value(
        executorId,
        'transactionId',
        "Does not reference a transaction. This might happen if you don't "
            'await all operations made inside a transaction, in which case the '
            'transaction might complete with pending operations.',
      );
    }

    try {
      switch (action) {
        case TransactionControl.commit:
          await executor.send();
          break;
        case TransactionControl.rollback:
          await executor.rollback();
          break;
        default:
          assert(false, 'Unknown TransactionControl');
      }
    } finally {
      _releaseExecutor(executorId!);
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
}

class _ServerDbUser implements QueryExecutorUser {
  final ServerImplementation _server;

  @override
  int schemaVersion = 0;

  _ServerDbUser(this._server); // will be overridden by client requests

  @override
  Future<void> beforeOpen(
      QueryExecutor executor, OpeningDetails details) async {
    final id = _server._putExecutor(executor, beforeCurrent: true);
    try {
      await _server._anyClient!.request(RunBeforeOpen(details, id));
    } finally {
      _server._releaseExecutor(id);
    }
  }
}
