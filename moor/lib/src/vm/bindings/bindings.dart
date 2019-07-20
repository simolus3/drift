// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import '../ffi/blob.dart';
import '../ffi/open_platform_specific.dart';

import 'signatures.dart';
import 'types.dart';

// ignore_for_file: comment_references, non_constant_identifier_names

class _SQLiteBindings {
  DynamicLibrary sqlite;

  int Function(CString filename, Pointer<DatabasePointer> databaseOut,
      int flags, CString vfs) sqlite3_open_v2;

  int Function(DatabasePointer database) sqlite3_close_v2;
  void Function(Pointer<Void> ptr) sqlite3_free;

  int Function(
      DatabasePointer database,
      CString query,
      int nbytes,
      Pointer<StatementPointer> statementOut,
      Pointer<CString> tail) sqlite3_prepare_v2;

  int Function(
    DatabasePointer database,
    CString query,
    Pointer callback,
    Pointer cbFirstArg,
    Pointer errorMsgOut,
  ) sqlite3_exec;

  int Function(StatementPointer statement) sqlite3_step;

  int Function(StatementPointer statement) sqlite3_reset;

  int Function(StatementPointer statement) sqlite3_finalize;

  int Function(StatementPointer statement) sqlite3_column_count;

  CString Function(StatementPointer statement, int columnIndex)
      sqlite3_column_name;

  CString Function(StatementPointer statement, int columnIndex)
      sqlite3_column_decltype;

  int Function(StatementPointer statement, int columnIndex) sqlite3_column_type;

  ValuePointer Function(StatementPointer statement, int columnIndex)
      sqlite3_column_value;
  double Function(StatementPointer statement, int columnIndex)
      sqlite3_column_double;
  int Function(StatementPointer statement, int columnIndex) sqlite3_column_int;
  CString Function(StatementPointer statement, int columnIndex)
      sqlite3_column_text;
  CBlob Function(StatementPointer statement, int columnIndex)
      sqlite3_column_blob;

  /// Returns the amount of bytes to read when using [sqlite3_column_blob].
  int Function(StatementPointer statement, int columnIndex)
      sqlite3_column_bytes;

  int Function(DatabasePointer db) sqlite3_changes;
  int Function(DatabasePointer db) sqlite3_last_insert_rowid;

  CString Function(int code) sqlite3_errstr;
  CString Function(DatabasePointer database) sqlite3_errmsg;

  int Function(StatementPointer statement, int columnIndex, double value)
      sqlite3_bind_double;
  int Function(StatementPointer statement, int columnIndex, int value)
      sqlite3_bind_int;
  int Function(StatementPointer statement, int columnIndex, CString value)
      sqlite3_bind_text;
  int Function(
          StatementPointer statement, int columnIndex, CBlob value, int length)
      sqlite3_bind_blob;
  int Function(StatementPointer statement, int columnIndex) sqlite3_bind_null;

  _SQLiteBindings() {
    sqlite = dlopenPlatformSpecific('sqlite3');

    sqlite3_bind_double = sqlite
        .lookup<NativeFunction<sqlite3_bind_double_native>>(
            'sqlite3_bind_double')
        .asFunction();
    sqlite3_bind_int = sqlite
        .lookup<NativeFunction<sqlite3_bind_int_native>>('sqlite3_bind_int')
        .asFunction();
    sqlite3_bind_text = sqlite
        .lookup<NativeFunction<sqlite3_bind_text_native>>('sqlite3_bind_text')
        .asFunction();
    sqlite3_bind_blob = sqlite
        .lookup<NativeFunction<sqlite3_bind_blob_native>>('sqlite3_bind_blob')
        .asFunction();
    sqlite3_bind_null = sqlite
        .lookup<NativeFunction<sqlite3_bind_null_native>>('sqlite3_bind_null')
        .asFunction();
    sqlite3_open_v2 = sqlite
        .lookup<NativeFunction<sqlite3_open_v2_native_t>>('sqlite3_open_v2')
        .asFunction();
    sqlite3_close_v2 = sqlite
        .lookup<NativeFunction<sqlite3_close_v2_native_t>>('sqlite3_close_v2')
        .asFunction();
    sqlite3_free = sqlite
        .lookup<NativeFunction<sqlite3_free_native>>('sqlite3_free')
        .asFunction();
    sqlite3_prepare_v2 = sqlite
        .lookup<NativeFunction<sqlite3_prepare_v2_native_t>>(
            'sqlite3_prepare_v2')
        .asFunction();
    sqlite3_exec = sqlite
        .lookup<NativeFunction<sqlite3_exec_native>>('sqlite3_exec')
        .asFunction();
    sqlite3_step = sqlite
        .lookup<NativeFunction<sqlite3_step_native_t>>('sqlite3_step')
        .asFunction();
    sqlite3_reset = sqlite
        .lookup<NativeFunction<sqlite3_reset_native_t>>('sqlite3_reset')
        .asFunction();
    sqlite3_changes = sqlite
        .lookup<NativeFunction<sqlite3_changes_native>>('sqlite3_changes')
        .asFunction();
    sqlite3_last_insert_rowid = sqlite
        .lookup<NativeFunction<sqlite3_last_insert_rowid_native>>(
            'sqlite3_last_insert_rowid')
        .asFunction();
    sqlite3_finalize = sqlite
        .lookup<NativeFunction<sqlite3_finalize_native_t>>('sqlite3_finalize')
        .asFunction();
    sqlite3_errstr = sqlite
        .lookup<NativeFunction<sqlite3_errstr_native_t>>('sqlite3_errstr')
        .asFunction();
    sqlite3_errmsg = sqlite
        .lookup<NativeFunction<sqlite3_errmsg_native_t>>('sqlite3_errmsg')
        .asFunction();
    sqlite3_column_count = sqlite
        .lookup<NativeFunction<sqlite3_column_count_native_t>>(
            'sqlite3_column_count')
        .asFunction();
    sqlite3_column_name = sqlite
        .lookup<NativeFunction<sqlite3_column_name_native_t>>(
            'sqlite3_column_name')
        .asFunction();
    sqlite3_column_decltype = sqlite
        .lookup<NativeFunction<sqlite3_column_decltype_native_t>>(
            'sqlite3_column_decltype')
        .asFunction();
    sqlite3_column_type = sqlite
        .lookup<NativeFunction<sqlite3_column_type_native_t>>(
            'sqlite3_column_type')
        .asFunction();
    sqlite3_column_value = sqlite
        .lookup<NativeFunction<sqlite3_column_value_native_t>>(
            'sqlite3_column_value')
        .asFunction();
    sqlite3_column_double = sqlite
        .lookup<NativeFunction<sqlite3_column_double_native_t>>(
            'sqlite3_column_double')
        .asFunction();
    sqlite3_column_int = sqlite
        .lookup<NativeFunction<sqlite3_column_int_native_t>>(
            'sqlite3_column_int')
        .asFunction();
    sqlite3_column_text = sqlite
        .lookup<NativeFunction<sqlite3_column_text_native_t>>(
            'sqlite3_column_text')
        .asFunction();
    sqlite3_column_blob = sqlite
        .lookup<NativeFunction<sqlite3_column_blob_native_t>>(
            'sqlite3_column_blob')
        .asFunction();
    sqlite3_column_bytes = sqlite
        .lookup<NativeFunction<sqlite3_column_bytes_native_t>>(
            'sqlite3_column_bytes')
        .asFunction();
  }
}

_SQLiteBindings _cachedBindings;
_SQLiteBindings get bindings => _cachedBindings ??= _SQLiteBindings();
