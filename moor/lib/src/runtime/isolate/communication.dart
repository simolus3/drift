import 'dart:async';
import 'dart:isolate';

import 'package:pedantic/pedantic.dart';

/// An isolate communication setup where there's a single "server" isolate that
/// communicates with a varying amount of "client" isolates.
///
/// Each communication is bi-directional, meaning that both the server and the
/// client can send requests to each other and expect responses for that.
class IsolateCommunication {
  /// The [SendPort] used to send messages to the peer.
  final SendPort sendPort;

  /// The input stream of this channel. This could be a [ReceivePort].
  final Stream<dynamic> input;

  /// The coded responsible to transform application-specific messages into
  /// primitive objects.
  final MessageCodec messageCodec;

  StreamSubscription _inputSubscription;

  // note that there are two IsolateCommunication instances in each connection,
  // and each of them has an independent _currentRequestId field!
  int _currentRequestId = 0;
  final Completer<void> _closeCompleter = Completer();
  final Map<int, Completer> _pendingRequests = {};
  final StreamController<Request> _incomingRequests = StreamController();

  final bool _debugLog;

  IsolateCommunication._(this.sendPort, this.input, this.messageCodec,
      [this._debugLog = false]) {
    _inputSubscription = input.listen(_handleMessage);
  }

  /// Returns a future that resolves when this communication channel was closed,
  /// either via a call to [close] from this isolate or from the other isolate.
  Future<void> get closed => _closeCompleter.future;

  /// Whether this channel is closed at the moment.
  bool get isClosed => _closeCompleter.isCompleted;

  /// A stream of requests coming from the other peer.
  Stream<Request> get incomingRequests => _incomingRequests.stream;

  /// Establishes an [IsolateCommunication] by connecting to a [Server].
  ///
  /// The server must listen for incoming connections on the receiving end of
  /// [openConnectionPort].
  static Future<IsolateCommunication> connectAsClient(
      SendPort openConnectionPort, MessageCodec messageCodec,
      [bool debugLog = false]) async {
    final clientReceive = ReceivePort();
    final stream = clientReceive.asBroadcastStream();

    openConnectionPort.send(messageCodec
        ._encodeMessage(_ClientConnectionRequest(clientReceive.sendPort)));

    final response = messageCodec._decodeMessage(await stream.first)
        as _ServerConnectionResponse;

    final communication = IsolateCommunication._(
        response.sendPort, stream, messageCodec, debugLog);

    unawaited(communication.closed.then((_) => clientReceive.close()));

    return communication;
  }

  /// Closes the connection to the server.
  void close() {
    if (isClosed) return;

    _send(const _ConnectionClose());
    _closeLocally();
  }

  void _closeLocally() {
    _inputSubscription?.cancel();
    _closeCompleter.complete();

    for (final pending in _pendingRequests.values) {
      pending.completeError(const ConnectionClosedException());
    }
    _pendingRequests.clear();
  }

  void _handleMessage(dynamic msg) {
    msg = messageCodec._decodeMessage(msg);

    if (_debugLog) {
      print('[IN]: $msg');
    }

    if (msg is _ConnectionClose) {
      _closeLocally();
    } else if (msg is _Response) {
      final completer = _pendingRequests[msg.requestId];

      if (completer != null) {
        if (msg is _ErrorResponse) {
          final trace = msg.stackTrace != null
              ? StackTrace.fromString(msg.stackTrace)
              : null;

          completer.completeError(msg.error, trace);
        } else {
          completer.complete(msg.response);
        }

        _pendingRequests.remove(msg.requestId);
      }
    } else if (msg is Request) {
      _incomingRequests.add(msg);
    }
  }

  /// Sends a request and waits for the peer to reply with a value that is
  /// assumed to be of type [T].
  Future<T> request<T>(dynamic request) {
    final id = _currentRequestId++;
    final completer = Completer<T>();

    _pendingRequests[id] = completer;
    _send(Request._(id, request));
    return completer.future;
  }

  void _send(IsolateMessage msg) {
    if (isClosed) {
      throw StateError('Tried to send $msg over isolate channel, but the '
          'connection was closed!');
    }

    if (_debugLog) {
      print('[OUT]: $msg');
    }
    sendPort.send(messageCodec._encodeMessage(msg));
  }

  /// Sends a response for a handled [Request].
  void respond(Request request, dynamic response) {
    _send(_Response(request.id, response));
  }

  /// Sends an erroneous response for a [Request].
  void respondError(Request request, dynamic error, [StackTrace trace]) {
    // sending a message while closed will throw, so don't even try.
    if (isClosed) return;

    _send(_ErrorResponse(request.id, error.toString(), trace.toString()));
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

/// Contains logic to implement the server isolate as described in
/// [IsolateCommunication]. Note that an instance of this class should not be
/// sent across isolates.
class Server {
  final ReceivePort _openConnectionPort = ReceivePort();
  final StreamController<IsolateCommunication> _opened = StreamController();

  /// The coded responsible to transform application-specific messages into
  /// primitive objects.
  final MessageCodec messageCodec;

  /// The port that should be used by new clients when they want to establish
  /// a new connection.
  SendPort get portToOpenConnection => _openConnectionPort.sendPort;

  /// Returns all communication channels currently opened to this server.
  final List<IsolateCommunication> currentChannels = [];

  /// A stream of established [IsolateCommunication] channels after they were
  /// opened by the client. This is not a broadcast stream.
  Stream<IsolateCommunication> get openedConnections => _opened.stream;

  /// Opens a server in the current isolate.
  Server(this.messageCodec) {
    _openConnectionPort.listen(_handleMessageOnConnectionPort);
  }

  /// Closes this server instance and disposes associated resources.
  void close() {
    _openConnectionPort.close();
    _opened.close();

    for (final connected in currentChannels) {
      connected.close();
    }
  }

  void _handleMessageOnConnectionPort(dynamic message) {
    message = messageCodec._decodeMessage(message);

    if (message is _ClientConnectionRequest) {
      final receiveFromClient = ReceivePort();
      final communication = IsolateCommunication._(
        message.sendPort,
        receiveFromClient,
        messageCodec,
      );

      currentChannels.add(communication);
      _opened.add(communication);

      final response = _ServerConnectionResponse(receiveFromClient.sendPort);
      message.sendPort.send(messageCodec._encodeMessage(response));

      communication.closed.whenComplete(() {
        currentChannels.remove(communication);
        receiveFromClient.close();
      });
    }
  }
}

/// Class used to encode and decode messages.
///
/// As explained in [SendPort.send], we can only send some objects across
/// isolates, notably:
/// - primitive types (null, num, bool, double, String)
/// - instances of [SendPort]
/// - [TransferableTypedData]
/// - lists and maps thereof.
///
/// This class is used to ensure we only send those types over isolates.
abstract class MessageCodec {
  /// Default constant constructor so that subclasses can be constant.
  const MessageCodec();

  dynamic _encodeMessage(IsolateMessage message) {
    if (message is _ClientConnectionRequest) {
      return [_ClientConnectionRequest._tag, message.sendPort];
    } else if (message is _ServerConnectionResponse) {
      return [_ServerConnectionResponse._tag, message.sendPort];
    } else if (message is _ConnectionClose) {
      return _ConnectionClose._tag;
    } else if (message is Request) {
      return [Request._tag, message.id, encodePayload(message.payload)];
    } else if (message is _ErrorResponse) {
      return [
        _ErrorResponse._tag,
        message.requestId,
        Error.safeToString(message.error),
        message.stackTrace,
      ];
    } else if (message is _Response) {
      return [
        _Response._tag,
        message.requestId,
        encodePayload(message.response),
      ];
    }

    throw AssertionError('Unknown message: $message');
  }

  IsolateMessage _decodeMessage(dynamic encoded) {
    if (encoded is int) {
      // _ConnectionClosed is the only message only consisting of a tag
      assert(encoded == _ConnectionClose._tag);
      return const _ConnectionClose();
    }

    final components = encoded as List;
    final tag = components.first as int;

    switch (tag) {
      case _ClientConnectionRequest._tag:
        return _ClientConnectionRequest(components[1] as SendPort);
      case _ServerConnectionResponse._tag:
        return _ServerConnectionResponse(components[1] as SendPort);
      case Request._tag:
        return Request._(components[1] as int, decodePayload(components[2]));
      case _ErrorResponse._tag:
        return _ErrorResponse(
          components[1] as int, // request id
          components[2], // error
          components[3] as String /*?*/,
        );
      case _Response._tag:
        return _Response(components[1] as int, decodePayload(encoded[2]));
    }

    throw AssertionError('Unrecognized message: $encoded');
  }

  /// Encodes an application-specific [payload], which can be any Dart object,
  /// so that it can be sent via [SendPort.send].
  dynamic encodePayload(dynamic payload);

  /// Counter-part of [encodePayload], which should decode a payload encoded by
  /// that function.
  dynamic decodePayload(dynamic encoded);
}

/// Marker interface for classes that can be sent over this communication
/// protocol.
abstract class IsolateMessage {}

/// Sent from a client to a server in order to establish a connection.
class _ClientConnectionRequest implements IsolateMessage {
  static const _tag = 1;

  /// The [SendPort] for server to client communication.
  final SendPort sendPort;

  _ClientConnectionRequest(this.sendPort);
}

/// Reply from a [Server] to a [_ClientConnectionRequest] to indicate that the
/// connection has been established.
class _ServerConnectionResponse implements IsolateMessage {
  static const _tag = 2;

  /// The [SendPort] used by the client to send further messages to the
  /// [Server].
  final SendPort sendPort;

  _ServerConnectionResponse(this.sendPort);
}

/// Sent from any peer to close the connection.
class _ConnectionClose implements IsolateMessage {
  static const _tag = 3;

  const _ConnectionClose();
}

/// A request sent over an isolate connection. It is expected that the other
/// peer eventually answers with a matching response.
class Request implements IsolateMessage {
  static const _tag = 4;

  /// The id of this request, generated by the sender.
  final int id;

  /// The payload associated with this request
  final dynamic payload;

  Request._(this.id, this.payload);

  @override
  String toString() {
    return 'request (id = $id): $payload';
  }
}

class _Response implements IsolateMessage {
  static const _tag = 5;

  final int requestId;
  final dynamic response;

  _Response(this.requestId, this.response);

  @override
  String toString() {
    return 'response (id = $requestId): $response';
  }
}

class _ErrorResponse extends _Response {
  static const _tag = 6;

  final String stackTrace;

  dynamic get error => response;

  _ErrorResponse(int requestId, dynamic error, [this.stackTrace])
      : super(requestId, error);

  @override
  String toString() {
    return 'error response (id = $requestId): $error at $stackTrace';
  }
}

/// Exception thrown when there are outstanding pending requests at the time the
/// isolate connection was cancelled.
class ConnectionClosedException implements Exception {
  /// Constant constructor.
  const ConnectionClosedException();
}
