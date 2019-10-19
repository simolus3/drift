part of 'moor_isolate.dart';

abstract class _Message {}

abstract class _Request extends _Message {
  /// An id for this request that is unique per client.
  int id;
}

abstract class _Response extends _Message {
  /// The [_Request.id] from the request this is response to.
  int id;
}

/// A notification is only sent from the server
abstract class _Notification extends _Message {}

class _ClientHello extends _Message {
  /// The [SendPort] used by the server to send messages to this client.
  final SendPort sendMsgToClient;

  _ClientHello(this.sendMsgToClient);
}

class _ServerHello extends _Message {
  final SendPort sendToServer;

  _ServerHello(this.sendToServer);
}
