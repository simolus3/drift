import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:moor_ffi/database.dart';
import 'package:moor_ffi/src/api/result.dart';
import 'package:moor_ffi/src/bindings/constants.dart';
import 'package:moor_ffi/src/bindings/types.dart' as types;
import 'package:moor_ffi/src/bindings/bindings.dart';
import 'package:moor_ffi/src/ffi/blob.dart';
import 'package:moor_ffi/src/ffi/utils.dart';

part 'errors.dart';
part 'prepared_statement.dart';

const _openingFlags = Flags.SQLITE_OPEN_READWRITE | Flags.SQLITE_OPEN_CREATE;
const _readOnlyOpeningFlags = Flags.SQLITE_OPEN_READONLY;

/// A opened sqlite database.
class Database {
  final Pointer<types.Database> _db;
  final List<PreparedStatement> _preparedStmt = [];
  bool _isClosed = false;

  Database._(this._db);

  /// Opens the [file] as a sqlite3 database. The file will be created if it
  /// doesn't exist.
  factory Database.openFile(File file) => Database.open(file.absolute.path);

  /// Opens an in-memory sqlite3 database.
  factory Database.memory() => Database.open(':memory:');

  /// Opens an sqlite3 database from a filename.
  ///
  /// Unless [readOnly] is set to true, database is open in read/write mode.
  factory Database.open(String fileName, {bool readOnly = false}) {
    final dbOut = allocate<Pointer<types.Database>>();
    final pathC = CBlob.allocateString(fileName);
    final openingFlags =
        (readOnly ?? false) ? _readOnlyOpeningFlags : _openingFlags;

    final resultCode =
        bindings.sqlite3_open_v2(pathC, dbOut, openingFlags, nullPtr());
    final dbPointer = dbOut.value;

    dbOut.free();
    pathC.free();

    if (resultCode == Errors.SQLITE_OK) {
      return Database._(dbPointer);
    } else {
      bindings.sqlite3_close_v2(dbPointer);
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
    if (_isClosed) return;

    // close all prepared statements first
    _isClosed = true;
    for (final stmt in _preparedStmt) {
      stmt.close();
    }

    final code = bindings.sqlite3_close_v2(_db);
    SqliteException exception;
    if (code != Errors.SQLITE_OK) {
      exception = SqliteException._fromErrorCode(_db, code);
    }
    _isClosed = true;

    // we don't need to deallocate the _db pointer, sqlite takes care of that

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

    final sqlPtr = CBlob.allocateString(sql);
    final errorOut = allocate<Pointer<CBlob>>();

    final result =
        bindings.sqlite3_exec(_db, sqlPtr, nullPtr(), nullPtr(), errorOut);

    sqlPtr.free();

    final errorPtr = errorOut.value;
    errorOut.free();

    String errorMsg;
    if (!errorPtr.isNullPointer) {
      errorMsg = errorPtr.readString();
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

    final stmtOut = allocate<Pointer<types.Statement>>();
    final sqlPtr = CBlob.allocateString(sql);

    final resultCode =
        bindings.sqlite3_prepare_v2(_db, sqlPtr, -1, stmtOut, nullPtr());
    sqlPtr.free();

    final stmt = stmtOut.value;
    stmtOut.free();

    if (resultCode != Errors.SQLITE_OK) {
      // we don't need to worry about freeing the statement. If preparing the
      // statement was unsuccessful, stmtOut.load() will be null
      throw SqliteException._fromErrorCode(_db, resultCode);
    }

    final prepared = PreparedStatement._(stmt, this);
    _preparedStmt.add(prepared);

    return prepared;
  }

  /// Get the application defined version of this database.
  int userVersion() {
    final stmt = prepare('PRAGMA user_version');
    final result = stmt.select();
    stmt.close();

    return result.first.columnAt(0) as int;
  }

  /// Update the application defined version of this database.
  void setUserVersion(int version) {
    execute('PRAGMA user_version = $version');
  }

  /// Returns the amount of rows affected by the last INSERT, UPDATE or DELETE
  /// statement.
  int getUpdatedRows() {
    _ensureOpen();
    return bindings.sqlite3_changes(_db);
  }

  /// Returns the row-id of the last inserted row.
  int getLastInsertId() {
    _ensureOpen();
    return bindings.sqlite3_last_insert_rowid(_db);
  }
}
