import 'dart:async';
import 'dart:isolate';

import 'package:moor_ffi/database.dart';
import 'package:moor_ffi/src/impl/database.dart';

enum IsolateCommandType {
  openDatabase,
  closeDatabase,
  executeSqlDirectly,
  prepareStatement,
  getUserVersion,
  setUserVersion,
  getUpdatedRows,
  getLastInsertId,
  preparedSelect,
  preparedExecute,
  preparedClose
}

class IsolateCommand {
  final int requestId;
  final IsolateCommandType type;
  final dynamic data;

  /// If this command operates on a prepared statement, contains the id of that
  /// statement as sent by the background isolate.
  int preparedStatementId;

  IsolateCommand(this.requestId, this.type, this.data);
}

class IsolateResponse {
  final int requestId;
  final dynamic response;
  final dynamic error;

  IsolateResponse(this.requestId, this.response, this.error);
}

/// Communicates with a background isolate over an RPC-like api.
class DbOperationProxy {
  /// Stream of messages received by the background isolate.
  final StreamController<dynamic> backgroundMsgs;
  final ReceivePort _receivePort;
  final Map<int, Completer> _pendingRequests = {};

  final SendPort send;
  final Isolate isolate;

  var closed = false;

  int _currentRequestId = 0;

  DbOperationProxy(
      this.backgroundMsgs, this._receivePort, this.send, this.isolate) {
    backgroundMsgs.stream.listen(_handleResponse);
  }

  Future<dynamic> sendRequest(IsolateCommandType type, dynamic data,
      {int preparedStmtId}) {
    if (closed) {
      throw StateError('Tried to call a database method after .close()');
    }

    final id = _currentRequestId++;
    final cmd = IsolateCommand(id, type, data)
      ..preparedStatementId = preparedStmtId;
    final completer = Completer();
    _pendingRequests[id] = completer;

    send.send(cmd);

    return completer.future;
  }

  void _handleResponse(dynamic response) {
    if (response is IsolateResponse) {
      final completer = _pendingRequests.remove(response.requestId);
      if (response.error != null) {
        completer.completeError(response.error);
      } else {
        completer.complete(response.response);
      }
    }
  }

  void close() {
    closed = true;
    _receivePort.close();
    backgroundMsgs.close();
    isolate.kill();
  }

  static Future<DbOperationProxy> spawn() async {
    final foregroundReceive = ReceivePort();
    final backgroundSend = foregroundReceive.sendPort;
    final isolate = await Isolate.spawn(_entryPoint, backgroundSend,
        debugName: 'moor_ffi background isolate');

    final controller = StreamController.broadcast();
    foregroundReceive.listen(controller.add);

    final foregroundSend = await controller.stream
        .firstWhere((msg) => msg is SendPort) as SendPort;

    return DbOperationProxy(
        controller, foregroundReceive, foregroundSend, isolate);
  }

  static void _entryPoint(SendPort backgroundSend) {
    final backgroundReceive = ReceivePort();
    final foregroundSend = backgroundReceive.sendPort;

    // inform the main isolate about the created send port
    backgroundSend.send(foregroundSend);

    BackgroundIsolateRunner(backgroundReceive, backgroundSend).start();
  }
}

class BackgroundIsolateRunner {
  final ReceivePort receive;
  final SendPort send;

  Database db;
  List<PreparedStatement> stmts = [];

  BackgroundIsolateRunner(this.receive, this.send);

  void start() {
    receive.listen((data) {
      if (data is IsolateCommand) {
        try {
          final response = _handleCommand(data);
          send.send(IsolateResponse(data.requestId, response, null));
        } catch (e) {
          if (e is Error) {
            // errors contain a StackTrace, which cannot be sent. So we just
            // send the description of that stacktrace.
            final exception =
                Exception('Error in background isolate: $e\n${e.stackTrace}');
            send.send(IsolateResponse(data.requestId, null, exception));
          } else {
            send.send(IsolateResponse(data.requestId, null, e));
          }
        }
      }
    });
  }

  dynamic _handleCommand(IsolateCommand cmd) {
    switch (cmd.type) {
      case IsolateCommandType.openDatabase:
        assert(db == null);
        db = Database.open(cmd.data as String);
        break;
      case IsolateCommandType.closeDatabase:
        db?.close();
        stmts.clear();
        db = null;
        break;
      case IsolateCommandType.executeSqlDirectly:
        db.execute(cmd.data as String);
        break;
      case IsolateCommandType.prepareStatement:
        final stmt = db.prepare(cmd.data as String);
        stmts.add(stmt);
        return stmts.length - 1;
      case IsolateCommandType.getUserVersion:
        return db.userVersion();
      case IsolateCommandType.setUserVersion:
        final version = cmd.data as int;
        db.setUserVersion(version);
        break;
      case IsolateCommandType.getUpdatedRows:
        return db.getUpdatedRows();
      case IsolateCommandType.getLastInsertId:
        return db.getLastInsertId();
      case IsolateCommandType.preparedSelect:
        final stmt = stmts[cmd.preparedStatementId];
        return stmt.select(cmd.data as List);
      case IsolateCommandType.preparedExecute:
        final stmt = stmts[cmd.preparedStatementId];
        stmt.execute(cmd.data as List);
        break;
      case IsolateCommandType.preparedClose:
        final index = cmd.preparedStatementId;
        stmts[index].close();
        stmts.removeAt(index);
        break;
    }
  }
}
