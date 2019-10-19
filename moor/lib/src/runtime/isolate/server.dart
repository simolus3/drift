part of 'moor_isolate.dart';

/// A "server" runs in an [Isolate] and takes requests from "client" isolates.
class _Server {
  /// The [ReceivePort] used to establish connections with new clients. This is
  /// the pendant to [MoorIsolate._connectToDb].
  ReceivePort _connectionRequest;

  DatabaseConnection _connection;

  final List<_ConnectedClient> _clients = [];

  _Server(DatabaseOpener opener, SendPort sendPort) {
    _connection = opener();

    _connectionRequest = ReceivePort();
    _connectionRequest.listen(_handleConnectionRequest);
    sendPort.send(_connectionRequest.sendPort);
  }

  void _handleConnectionRequest(dynamic message) {
    if (message is! _ClientHello) {
      throw AssertionError('Unexpected initial message from client: $message');
      // we can't replay this to the client because we don't have a SendPort
    }

    final sendToClient = (message as _ClientHello).sendMsgToClient;
    final receive = ReceivePort();
    final client = _ConnectedClient(receive, sendToClient);

    receive.listen((data) {
      if (data is _Request) {
        _handleRequest(client, data);
      }
      // todo send error message to client when it sends something that isn't
      // a request
    });

    sendToClient.send(_ServerHello(receive.sendPort));
  }

  void _handleRequest(_ConnectedClient client, _Request request) {}
}

class _ConnectedClient {
  final ReceivePort receiveFromClient;
  final SendPort sendToClient;

  _ConnectedClient(this.receiveFromClient, this.sendToClient);
}
