import 'dart:async';
import 'dart:collection';
import 'dart:ffi';
import 'dart:isolate';

import 'package:meta/meta.dart';
import 'package:sqlite3_connection_pool/sqlite3_connection_pool.dart';

/// A isolate capable of running database queries.
///
/// This shares the raw [PoolConnection] with the worker. For this to be safe,
/// this must only be called in [AsyncConnection.unsafeAccess] callbacks. No
/// method here closes the database or uses it after the request is complete.
final class DatabaseWorker {
  Isolate? _isolate;
  final SendPort _sendCommands;
  final ReceivePort _onMessage, _onExit;

  final Map<int, Completer<Object?>> _inflightRequests = {};
  var _nextRequestId = 0;
  final Completer<void> _closed = Completer.sync();

  DatabaseWorker._(
    this._isolate,
    this._sendCommands,
    this._onMessage,
    this._onExit,
  ) {
    _onMessage.listen((msg) {
      final response = msg as List<Object?>;

      final requestId = response[0] as int;
      final completer = _inflightRequests.remove(requestId);
      if (completer != null) {
        if (response.length == 2) {
          completer.complete(response[1]);
        } else {
          final error = response[1]!;
          final stack = switch (response[2]) {
            final StackTrace s => s,
            final other => StackTrace.fromString(other.toString()),
          };

          completer.completeError(error, stack);
        }
      }
    });

    _onExit.listen((_) {
      // Open receive ports keep the owning isolate alive, so close them once
      // the worker is gone.
      _onMessage.close();
      _onExit.close();
      _closed.complete();

      for (final request in _inflightRequests.values) {
        request.completeError(StateError('Isolate closed before response'));
      }

      _inflightRequests.clear();
    });
  }

  /// Kills the worker isolate and waits for the shutdown message.
  Future<void> close() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    return _closed.future;
  }

  /// Makes the worker isolate run [work] on [connection].
  Future<T> execute<T>(
    PoolConnection connection,
    T Function(PoolConnection) work,
  ) async {
    final id = _nextRequestId++;
    final msg = _WorkRequest(_RequestId.fromConnection(id, connection), work);
    final completion = _inflightRequests[id] = Completer<T>();

    _sendCommands.send(msg);
    return await completion.future;
  }

  /// Spawns a new isolate able to handle database work items.
  static Future<DatabaseWorker> spawn({required String debugName}) async {
    final receive = ReceivePort('responses from $debugName');
    final init = ReceivePort('init $debugName');
    final onExit = ReceivePort('exit port for $debugName');

    final isolate = await Isolate.spawn(
      _entrypoint,
      (receive.sendPort, init.sendPort),
      debugName: debugName,
      onExit: onExit.sendPort,
    );
    final sendCommands = (await init.first) as SendPort;
    init.close();
    return DatabaseWorker._(isolate, sendCommands, receive, onExit);
  }

  static void _entrypoint((SendPort, SendPort) arg) {
    final (parent, init) = arg;
    final requests = ReceivePort('receive requests');
    init.send(requests.sendPort);

    requests.listen((message) {
      final request = message as _WorkRequest;
      final requestId = request.requestId.requestId;
      final connection = request.requestId.connection;

      try {
        parent.send([requestId, request.closure(connection)]);
      } catch (e, s) {
        try {
          parent.send([requestId, e, s]);
        } on Object {
          // In rare cases, the error may not be suitable for sending through
          // ports.
          parent.send([requestId, Error.safeToString(e), s.toString()]);
        }
      }
    });
  }
}

/// A pool of database workers.
@internal
final class DatabaseWorkers {
  final String _path;
  var _workerId = 0;
  final Queue<DatabaseWorker> _workers;

  DatabaseWorkers(this._path, int capacity) : _workers = ListQueue(capacity);

  Future<DatabaseWorker> acquireWorker() async {
    if (_workers.isEmpty) {
      return await DatabaseWorker.spawn(
        debugName: 'Worker ${_workerId++} for $_path',
      );
    } else {
      return _workers.removeFirst();
    }
  }

  void returnIsolateWorker(DatabaseWorker worker) {
    _workers.addLast(worker);
  }

  Future<void> close() {
    return _workers.map((e) => e.close()).wait;
  }
}

@pragma('vm:deeply-immutable')
final class _RequestId {
  final int requestId;
  final int connectionPointer;

  _RequestId(this.requestId, this.connectionPointer);

  _RequestId.fromConnection(this.requestId, PoolConnection conn)
    : connectionPointer = conn.unsafePointer.address;

  PoolConnection get connection =>
      PoolConnection.unsafeFromPointer(Pointer.fromAddress(connectionPointer));
}

final class _WorkRequest<T> {
  final _RequestId requestId;
  final T Function(PoolConnection) closure;

  _WorkRequest(this.requestId, this.closure);
}
