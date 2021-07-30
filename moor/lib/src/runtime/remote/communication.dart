import 'dart:async';

import 'package:moor/src/runtime/api/runtime_api.dart';
import 'package:stream_channel/stream_channel.dart';

import '../cancellation_zone.dart';
import 'protocol.dart';

/// Wrapper around a two-way communication channel to support requests and
/// responses.
class MoorCommunication {
  static const _protocol = MoorProtocol();

  final StreamChannel<Object?> _channel;
  final bool _debugLog;

  StreamSubscription? _inputSubscription;

  // note that there are two MoorCommunication instances in each connection,
  // (one per remote). Each of them has an independent _currentRequestId field
  int _currentRequestId = 0;
  final Completer<void> _closeCompleter = Completer();
  final Map<int, Completer> _pendingRequests = {};
  final StreamController<Request> _incomingRequests =
      StreamController(sync: true);

  /// Starts a moor communication channel over a raw [StreamChannel].
  MoorCommunication(this._channel, [this._debugLog = false]) {
    _inputSubscription = _channel.stream.listen(
      _handleMessage,
      onDone: _closeCompleter.complete,
    );
  }

  /// Returns a future that resolves when this communication channel was closed,
  /// either via a call to [close] from this isolate or from the other isolate.
  Future<void> get closed => _closeCompleter.future;

  /// Whether this channel is closed at the moment.
  bool get isClosed => _closeCompleter.isCompleted;

  /// A stream of requests coming from the other peer.
  Stream<Request> get incomingRequests => _incomingRequests.stream;

  /// Returns a new request id to be used for the next request.
  int newRequestId() => _currentRequestId++;

  /// Closes the connection to the server.
  void close() {
    if (isClosed) return;

    _channel.sink.close();
    _closeLocally();
  }

  void _closeLocally() {
    _inputSubscription?.cancel();

    for (final pending in _pendingRequests.values) {
      pending.completeError(const ConnectionClosedException());
    }
    _pendingRequests.clear();
  }

  void _handleMessage(Object? msg) {
    msg = _protocol.deserialize(msg!);

    if (_debugLog) {
      moorRuntimeOptions.debugPrint('[IN]: $msg');
    }

    if (msg is SuccessResponse) {
      final completer = _pendingRequests[msg.requestId];
      completer?.complete(msg.response);
      _pendingRequests.remove(msg.requestId);
    } else if (msg is ErrorResponse) {
      final completer = _pendingRequests[msg.requestId];
      final trace = msg.stackTrace != null
          ? StackTrace.fromString(msg.stackTrace!)
          : null;
      completer?.completeError(msg.error, trace);
      _pendingRequests.remove(msg.requestId);
    } else if (msg is Request) {
      _incomingRequests.add(msg);
    } else if (msg is CancelledResponse) {
      final completer = _pendingRequests[msg.requestId];
      completer?.completeError(const CancellationException());
    }
  }

  /// Sends a request and waits for the peer to reply with a value that is
  /// assumed to be of type [T].
  ///
  /// The [requestId] parameter can be used to set a fixed request id for the
  /// request.
  Future<T> request<T>(Object? request, {int? requestId}) {
    final id = requestId ?? newRequestId();
    final completer = Completer<T>();

    _pendingRequests[id] = completer;
    _send(Request(id, request));
    return completer.future;
  }

  void _send(Message msg) {
    if (isClosed) {
      throw StateError('Tried to send $msg over isolate channel, but the '
          'connection was closed!');
    }

    if (_debugLog) {
      moorRuntimeOptions.debugPrint('[OUT]: $msg');
    }
    _channel.sink.add(_protocol.serialize(msg));
  }

  /// Sends a response for a handled [Request].
  void respond(Request request, Object? response) {
    _send(SuccessResponse(request.id, response));
  }

  /// Sends an erroneous response for a [Request].
  void respondError(Request request, dynamic error, [StackTrace? trace]) {
    // sending a message while closed will throw, so don't even try.
    if (isClosed) return;

    if (error is CancellationException) {
      _send(CancelledResponse(request.id));
    } else {
      _send(ErrorResponse(request.id, error.toString(), trace.toString()));
    }
  }

  /// Utility that listens to [incomingRequests] and invokes the [handler] on
  /// each request, sending the result back to the originating client. If
  /// [handler] throws, the error will be re-directed to the client. If
  /// [handler] returns a [Future], it will be awaited.
  void setRequestHandler(dynamic Function(Request) handler) {
    incomingRequests.listen((request) {
      try {
        final result = handler(request);

        if (result is Future) {
          result.then(
            (value) => respond(request, value),
            onError: (e, StackTrace s) {
              respondError(request, e, s);
            },
          );
        } else {
          respond(request, result);
        }
      } catch (e, s) {
        respondError(request, e, s);
      }
    });
  }
}

/// Exception thrown when there are outstanding pending requests at the time the
/// isolate connection was cancelled.
class ConnectionClosedException implements Exception {
  /// Constant constructor.
  const ConnectionClosedException();
}
