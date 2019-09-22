import 'dart:async';
import 'dart:io';

import 'package:moor_ffi/database.dart';
import 'package:moor_ffi/src/impl/database.dart';
import 'package:moor_ffi/src/impl/isolate/background.dart';

class IsolateDb implements BaseDatabase {
  /// Spawns a background isolate and opens the [file] on that isolate. The file
  /// will be created if it doesn't exist.
  static Future<IsolateDb> openFile(File file) => open(file.absolute.path);

  /// Opens a in-memory database on a background isolates.
  ///
  /// If you're not using extensive queries, a synchronous [Database] will
  /// provide better performance for in-memory databases!
  static Future<IsolateDb> openMemory() => open(':memory:');

  /// Spawns a background isolate and opens a sqlite3 database from its
  /// filename.
  static Future<IsolateDb> open(String path) async {
    final proxy = await DbOperationProxy.spawn();

    final isolate = IsolateDb._(proxy);
    await isolate._open(path);

    return isolate;
  }

  final DbOperationProxy _proxy;
  IsolateDb._(this._proxy);

  Future<int> _sendAndAssumeInt(IsolateCommandType type, [dynamic data]) async {
    return await _proxy.sendRequest(type, data) as int;
  }

  Future<void> _open(String path) {
    return _proxy.sendRequest(IsolateCommandType.openDatabase, path);
  }

  @override
  Future<void> close() async {
    await _proxy.sendRequest(IsolateCommandType.closeDatabase, null);
    _proxy.close();
  }

  @override
  Future<void> execute(String sql) async {
    await _proxy.sendRequest(IsolateCommandType.executeSqlDirectly, sql);
  }

  @override
  Future<int> getLastInsertId() async {
    return _sendAndAssumeInt(IsolateCommandType.getLastInsertId);
  }

  @override
  Future<int> getUpdatedRows() async {
    return _sendAndAssumeInt(IsolateCommandType.getUpdatedRows);
  }

  @override
  FutureOr<BasePreparedStatement> prepare(String sql) async {
    final id =
        await _sendAndAssumeInt(IsolateCommandType.prepareStatement, sql);
    return IsolatePreparedStatement(this, id);
  }

  @override
  Future<void> setUserVersion(int version) async {
    await _proxy.sendRequest(IsolateCommandType.setUserVersion, version);
  }

  @override
  Future<int> userVersion() async {
    return _sendAndAssumeInt(IsolateCommandType.getUserVersion);
  }
}

class IsolatePreparedStatement implements BasePreparedStatement {
  final IsolateDb _db;
  final int _id;

  IsolatePreparedStatement(this._db, this._id);

  @override
  Future<void> close() async {
    await _db._proxy.sendRequest(IsolateCommandType.preparedClose, null,
        preparedStmtId: _id);
  }

  @override
  Future<void> execute([List params]) async {
    await _db._proxy.sendRequest(IsolateCommandType.preparedExecute, params,
        preparedStmtId: _id);
  }

  @override
  Future<Result> select([List params]) async {
    final response = await _db._proxy.sendRequest(
        IsolateCommandType.preparedSelect, params,
        preparedStmtId: _id);
    return response as Result;
  }
}
