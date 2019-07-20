import 'dart:collection';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:moor/src/vm/bindings/constants.dart';
import 'package:moor/src/vm/bindings/types.dart';
import 'package:moor/src/vm/bindings/bindings.dart';
import 'package:moor/src/vm/ffi/blob.dart';

part 'errors.dart';
part 'prepared_statement.dart';
part 'result.dart';

const _openingFlags = Flags.SQLITE_OPEN_READWRITE | Flags.SQLITE_OPEN_CREATE;

final _nullPtr = fromAddress(0);

class Database {
  final DatabasePointer _db;
  final List<PreparedStatement> _preparedStmt = [];
  bool _isClosed;

  Database._(this._db);

  /// Opens the [file] as a sqlite3 database. The file will be created if it
  /// doesn't exist.
  factory Database.openFile(File file) => Database.open(file.absolute.path);

  /// Opens an in-memory sqlite3 database.
  factory Database.memory() => Database.open(':memory:');

  /// Opens an sqlite3 database from a filename.
  factory Database.open(String fileName) {
    final dbOut = allocate<DatabasePointer>();
    final pathC = CString.allocate(fileName);

    final resultCode =
        bindings.sqlite3_open_v2(pathC, dbOut, _openingFlags, _nullPtr.cast());
    final dbPointer = dbOut.load<DatabasePointer>();

    dbOut.free();
    pathC.free();

    if (resultCode == Errors.SQLITE_OK) {
      return Database._(dbPointer);
    } else {
      throw SqliteException._fromErrorCode(dbPointer, resultCode);
    }
  }

  void _ensureOpen() {
    if (_isClosed) {
      throw Exception('This database has already been closed');
    }
  }

  /// Closes this database connection and releases the resources it uses. If
  /// an error occurs while closing the database, an exception will be thrown.
  /// The allocated memory will be freed either way.
  void close() {
    final code = bindings.sqlite3_close_v2(_db);
    SqliteException exception;
    if (code != Errors.SQLITE_OK) {
      exception = SqliteException._fromErrorCode(_db, code);
    }
    _isClosed = true;

    for (var stmt in _preparedStmt) {
      stmt.close();
    }
    _db.free();

    if (exception != null) {
      throw exception;
    }
  }

  void _handleStmtFinalized(PreparedStatement stmt) {
    if (!_isClosed) {
      _preparedStmt.remove(stmt);
    }
  }

  /// Executes the [sql] statement and ignores the result. Will throw if an
  /// error occurs while executing.
  void execute(String sql) {
    _ensureOpen();
    final sqlPtr = CString.allocate(sql);
    final errorOut = allocate<CString>();

    final result = bindings.sqlite3_exec(
        _db, sqlPtr, _nullPtr.cast(), _nullPtr.cast(), errorOut);

    sqlPtr.free();

    final errorPtr = errorOut.load<Pointer>();
    errorOut.free();

    String errorMsg;
    if (errorPtr.address != 0) {
      errorMsg = CString.fromC(errorPtr.cast());
      // the message was allocated from sqlite, we need to free it
      bindings.sqlite3_free(errorPtr.cast());
    }

    if (result != Errors.SQLITE_OK) {
      throw SqliteException(errorMsg);
    }
  }

  /// Prepares the [sql] statement.
  PreparedStatement prepare(String sql) {
    _ensureOpen();

    final stmtOut = allocate<StatementPointer>();
    final sqlPtr = CString.allocate(sql);

    final resultCode =
        bindings.sqlite3_prepare_v2(_db, sqlPtr, -1, stmtOut, _nullPtr.cast());
    sqlPtr.free();

    final stmt = stmtOut.load<StatementPointer>();
    stmtOut.free();

    if (resultCode != Errors.SQLITE_OK) {
      // we don't need to worry about freeing the statement. If preparing the
      // statement was unsuccessful, stmtOut.load() will be the null pointer
      throw SqliteException._fromErrorCode(_db, resultCode);
    }

    return PreparedStatement._(stmt, this);
  }

  /// Get the application defined version of this database.
  int get userVersion {
    final stmt = prepare('PRAGMA user_version');
    final result = stmt.select();
    stmt.close();

    return result.first.columnAt(0) as int;
  }

  /// Update the application defined version of this database.
  set userVersion(int version) {
    execute('PRAGMA user_version = $version');
  }

  /// Returns the amount of rows affected by the last INSERT, UPDATE or DELETE
  /// statement.
  int get updatedRows {
    _ensureOpen();
    return bindings.sqlite3_changes(_db);
  }

  /// Returns the row-id of the last inserted row.
  int get lastInsertId {
    _ensureOpen();
    return bindings.sqlite3_last_insert_rowid(_db);
  }
}
