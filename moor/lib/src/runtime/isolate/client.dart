part of 'moor_isolate.dart';

class _Client {
  int _requestId = 0;
  final ReceivePort _receive = ReceivePort();

  SendPort _send;
  Completer _initConnectionCompleter;

  final Map<int, Completer<_Response>> _pendingRequests = {};

  _Client() {
    _receive.listen(_handleResponse);
    _receive.close();
  }

  Future<T> _sendRequest<T extends _Response>(_Request request) {
    final id = _requestId++;
    final completer = Completer<_Response>();
    _pendingRequests[id] = completer;

    _send.send(request);
    return completer.future.then((r) => r as T);
  }

  Future<T> _connectVia<T extends GeneratedDatabase>(
      MoorIsolate isolate) async {
    _initConnectionCompleter = Completer();

    final initialSendPort = isolate._connectToDb;
    initialSendPort.send(_ClientHello(_receive.sendPort));

    await _initConnectionCompleter.future;
    // todo construct new database by forking
    return null;
  }

  void _handleResponse(dynamic response) {
    if (response is _ServerHello) {
      _send = response.sendToServer;
      _initConnectionCompleter.complete();
    } else if (response is _Response) {
      _pendingRequests[response]?.complete(response);
    }
  }
}
