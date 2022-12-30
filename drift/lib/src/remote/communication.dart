import 'dart:async';

import 'package:drift/src/runtime/api/runtime_api.dart';
import 'package:meta/meta.dart';
import 'package:stream_channel/stream_channel.dart';

import '../runtime/cancellation_zone.dart';
import 'protocol.dart';

/// Wrapper around a two-way communication channel to support requests and
/// responses.
@internal
class DriftCommunication {
  static const _protocol = DriftProtocol();

  final StreamChannel<Object?> _channel;
  final bool _debugLog;
  final bool _serialize;

  StreamSubscription? _inputSubscription;

  // note that there are two DriftCommunication instances in each connection,
  // (one per remote). Each of them has an independent _currentRequestId field
  int _currentRequestId = 0;
  final Map<int, _PendingRequest> _pendingRequests = {};
  final StreamController<Request> _incomingRequests =
      StreamController(sync: true);

  bool _startedClosingLocally = false;
  final Completer<void> _closeCompleter = Completer();

  /// Starts a drift communication channel over a raw [StreamChannel].
  DriftCommunication(this._channel,
      {bool debugLog = false, bool serialize = true})
      : _debugLog = debugLog,
        _serialize = serialize {
    _inputSubscription = _channel.stream.listen(
      _handleMessage,
      onDone: () {
        // Channel closed => Complete pending requests with an error
        for (final pending in _pendingRequests.values) {
          pending.completeWithError(const ConnectionClosedException());
        }
        _pendingRequests.clear();

        _closeCompleter.complete();
      },
    );
  }

  /// Returns a future that resolves when this communication channel was closed,
  /// either via a call to [close] from this isolate or from the other isolate.
  Future<void> get closed => _closeCompleter.future;

  /// Whether this channel is closed at the moment.
  bool get isClosed => _startedClosingLocally || _closeCompleter.isCompleted;

  /// A stream of requests coming from the other peer.
  Stream<Request> get incomingRequests => _incomingRequests.stream;

  /// Returns a new request id to be used for the next request.
  int newRequestId() => _currentRequestId++;

  /// Closes the connection to the server.
  Future<void> close() async {
    if (isClosed) return;

    _closeLocally();
    await _closeCompleter.future;
  }

  void _closeLocally() {
    _startedClosingLocally = true;
    _channel.sink.close();
    _inputSubscription?.cancel();
  }

  void _handleMessage(Object? msg) {
    if (_serialize) msg = _protocol.deserialize(msg!);

    if (_debugLog) {
      driftRuntimeOptions.debugPrint('[IN]: $msg');
    }

    if (msg is SuccessResponse) {
      final request = _pendingRequests.remove(msg.requestId);
      request?.completer.complete(msg.response);
    } else if (msg is ErrorResponse) {
      final requestId = msg.requestId;
      final request = _pendingRequests.remove(requestId);
      final backgroundTrace = msg.stackTrace != null
          ? StackTrace.fromString(msg.stackTrace!)
          : null;

      request?.completeWithError(
          DriftRemoteException._(msg.error, backgroundTrace));
      _pendingRequests.remove(msg.requestId);
    } else if (msg is Request) {
      _incomingRequests.add(msg);
    } else if (msg is CancelledResponse) {
      final request = _pendingRequests.remove(msg.requestId);

      request?.completeWithError(const CancellationException());
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

    _pendingRequests[id] = _PendingRequest(completer, StackTrace.current);

    _send(Request(id, request));
    return completer.future;
  }

  /// Sends the [notification] to the other remote.
  ///
  /// The acknowledgement from the remote will be ignored.
  void notify(Object? notification) {
    _send(Request(newRequestId(), notification));
  }

  void _send(Message msg) {
    if (isClosed) {
      throw StateError('Tried to send $msg over isolate channel, but the '
          'connection was closed!');
    }

    if (_debugLog) {
      driftRuntimeOptions.debugPrint('[OUT]: $msg');
    }

    _channel.sink.add(_serialize ? _protocol.serialize(msg) : msg);
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
    incomingRequests.listen((request) async {
      Object? response;

      try {
        response = await handler(request);
      } catch (e, s) {
        return respondError(request, e, s);
      }

      if (!isClosed) {
        respond(request, response);
      }
    });
  }
}

class _PendingRequest {
  final Completer completer;

  /// We capture the current stack trace when `request` is called so that, if
  /// an exception occurs on the remote peer, we can throw exceptions with a
  /// proper stack trace pointing torwards the causing invocation.
  final StackTrace requestTrace;

  _PendingRequest(this.completer, this.requestTrace);

  void completeWithError(Object error) {
    completer.completeError(error, requestTrace);
  }
}

/// Exception thrown when there are outstanding pending requests at the time the
/// isolate connection was cancelled.
class ConnectionClosedException implements Exception {
  /// Constant constructor.
  const ConnectionClosedException();
}

/// An exception reported on the other end of a drift remote protocol.
///
/// For a drift isolates, this exception is thrown if an error happened while
/// a background isolate tries to run your query.
class DriftRemoteException implements Exception {
  /// The original error on the remote peer.
  final Object remoteCause;

  /// The stack trace of the original error on the remote peer.
  final StackTrace? remoteStackTrace;

  DriftRemoteException._(this.remoteCause, this.remoteStackTrace);

  @override
  String toString() => remoteCause.toString();
}
