import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:meta/meta.dart';
import 'package:moor_ffi/database.dart';
import 'package:moor_ffi/src/api/result.dart';
import 'package:moor_ffi/src/bindings/constants.dart';
import 'package:moor_ffi/src/bindings/signatures.dart';
import 'package:moor_ffi/src/bindings/types.dart' as types;
import 'package:moor_ffi/src/bindings/bindings.dart';
import 'package:moor_ffi/src/ffi/blob.dart';
import 'package:moor_ffi/src/ffi/utils.dart';

part 'errors.dart';
part 'prepared_statement.dart';

const _openingFlags = Flags.SQLITE_OPEN_READWRITE | Flags.SQLITE_OPEN_CREATE;

/// A opened sqlite database.
class Database {
  final Pointer<types.Database> _db;
  final List<PreparedStatement> _preparedStmt = [];
  final List<Pointer<Void>> _furtherAllocations = [];

  bool _isClosed = false;

  Database._(this._db);

  /// Opens the [file] as a sqlite3 database. The file will be created if it
  /// doesn't exist.
  factory Database.openFile(File file) => Database.open(file.absolute.path);

  /// Opens an in-memory sqlite3 database.
  factory Database.memory() => Database.open(':memory:');

  /// Opens an sqlite3 database from a filename.
  factory Database.open(String fileName) {
    final dbOut = allocate<Pointer<types.Database>>();
    final pathC = CBlob.allocateString(fileName);

    final resultCode =
        bindings.sqlite3_open_v2(pathC, dbOut, _openingFlags, nullPtr());
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

    for (final additional in _furtherAllocations) {
      additional.free();
    }

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

  /// Registers a custom sqlite function by its [name].
  ///
  /// The function must take [argumentCount] arguments, and it may not take more
  /// than 127 arguments. If it can take a variable amount of arguments,
  /// [argumentCount] should be set to `-1`.
  ///
  /// When the output of the function depends solely on its input,
  /// [isDeterministic] should be set. This allows sqlite's query planer to make
  /// further optimizations.
  /// When [directOnly] is set (defaults to true), the function can't be used
  /// outside a query (e.g. in triggers, views, check constraints, index
  /// expressions, etc.). Unless necessary, this should be enabled for security
  /// purposes. See the discussion at the link for more details
  /// The length of the utf8 encoding of [name] must not exceed 255 bytes.
  ///
  /// See also:
  ///  - https://sqlite.org/c3ref/create_function.html
  ///  - [SqliteFunctionHandler]
  @visibleForTesting
  void createFunction(
    String name,
    int argumentCount,
    Pointer<NativeFunction<sqlite3_function_handler>> implementation, {
    bool isDeterministic = false,
    bool directOnly = true,
  }) {
    _ensureOpen();
    final encodedName = Uint8List.fromList(utf8.encode(name));
    // length of encoded name is limited to 255 bytes in utf8, excluding the 0
    // terminator
    if (encodedName.length > 255) {
      throw ArgumentError.value(
          name, 'name', 'Must be at most 255 bytes when encoded as utf8');
    }

    // argument length should be between -1 and 127
    if (argumentCount < -1 || argumentCount > 127) {
      throw ArgumentError.value(
          argumentCount, 'argumentCount', 'Should be between -1 and 127');
    }

    final namePtr = CBlob.allocate(encodedName, paddingAtEnd: 1);
    _furtherAllocations.add(namePtr.cast());

    var textFlag = TextEncodings.SQLITE_UTF8;

    if (isDeterministic) textFlag |= FunctionFlags.SQLITE_DETERMINISTIC;
    if (directOnly) textFlag |= FunctionFlags.SQLITE_DIRECTONLY;

    final result = bindings.sqlite3_create_function_v2(
      _db,
      namePtr.cast(),
      argumentCount,
      textFlag,
      nullPtr(), // *pApp, we don't use that
      implementation,
      nullPtr(), // *xStep, null for regular functions
      nullPtr(), // *xFinal, null for regular functions
      nullPtr(), // finalizer for *pApp,
    );

    if (result != Errors.SQLITE_OK) {
      throw SqliteException._fromErrorCode(_db, result);
    }
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
