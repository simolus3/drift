// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:moor_ffi/open_helper.dart';

import '../ffi/blob.dart';

import 'signatures.dart';
import 'types.dart';

// ignore_for_file: comment_references, non_constant_identifier_names

class _SQLiteBindings {
  DynamicLibrary sqlite;

  int Function(Pointer<CBlob> filename, Pointer<Pointer<Database>> databaseOut,
      int flags, Pointer<CBlob> vfs) sqlite3_open_v2;

  int Function(Pointer<Database> database) sqlite3_close_v2;
  void Function(Pointer<Void> ptr) sqlite3_free;

  int Function(
      Pointer<Database> database,
      Pointer<CBlob> query,
      int nbytes,
      Pointer<Pointer<Statement>> statementOut,
      Pointer<Pointer<CBlob>> tail) sqlite3_prepare_v2;

  int Function(
    Pointer<Database> database,
    Pointer<CBlob> query,
    Pointer<Void> callback,
    Pointer<Void> cbFirstArg,
    Pointer<Pointer<CBlob>> errorMsgOut,
  ) sqlite3_exec;

  int Function(Pointer<Statement> statement) sqlite3_step;

  int Function(Pointer<Statement> statement) sqlite3_reset;

  int Function(Pointer<Statement> statement) sqlite3_finalize;

  int Function(Pointer<Statement> statement) sqlite3_column_count;

  Pointer<CBlob> Function(Pointer<Statement> statement, int columnIndex)
      sqlite3_column_name;

  int Function(Pointer<Statement> statement, int columnIndex)
      sqlite3_column_type;

  double Function(Pointer<Statement> statement, int columnIndex)
      sqlite3_column_double;
  int Function(Pointer<Statement> statement, int columnIndex)
      sqlite3_column_int64;
  Pointer<CBlob> Function(Pointer<Statement> statement, int columnIndex)
      sqlite3_column_text;
  Pointer<CBlob> Function(Pointer<Statement> statement, int columnIndex)
      sqlite3_column_blob;

  /// Returns the amount of bytes to read when using [sqlite3_column_blob].
  int Function(Pointer<Statement> statement, int columnIndex)
      sqlite3_column_bytes;

  int Function(Pointer<Database> db) sqlite3_changes;
  int Function(Pointer<Database> db) sqlite3_last_insert_rowid;

  Pointer<CBlob> Function(int code) sqlite3_errstr;
  Pointer<CBlob> Function(Pointer<Database> database) sqlite3_errmsg;
  int Function(Pointer<Database> database, int onOff)
      sqlite3_extended_result_codes;

  int Function(Pointer<Statement> statement, int columnIndex, double value)
      sqlite3_bind_double;
  int Function(Pointer<Statement> statement, int columnIndex, int value)
      sqlite3_bind_int64;
  int Function(
      Pointer<Statement> statement,
      int columnIndex,
      Pointer<CBlob> value,
      int minusOne,
      Pointer<Void> disposeCb) sqlite3_bind_text;
  int Function(
      Pointer<Statement> statement,
      int columnIndex,
      Pointer<CBlob> value,
      int length,
      Pointer<Void> disposeCb) sqlite3_bind_blob;
  int Function(Pointer<Statement> statement, int columnIndex) sqlite3_bind_null;

  _SQLiteBindings() {
    sqlite = open.openSqlite();

    sqlite3_bind_double = sqlite
        .lookup<NativeFunction<sqlite3_bind_double_native>>(
            'sqlite3_bind_double')
        .asFunction();
    sqlite3_bind_int64 = sqlite
        .lookup<NativeFunction<sqlite3_bind_int64_native>>('sqlite3_bind_int64')
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
    sqlite3_extended_result_codes = sqlite
        .lookup<NativeFunction<sqlite3_extended_result_codes_t>>(
            'sqlite3_extended_result_codes')
        .asFunction();
    sqlite3_column_count = sqlite
        .lookup<NativeFunction<sqlite3_column_count_native_t>>(
            'sqlite3_column_count')
        .asFunction();
    sqlite3_column_name = sqlite
        .lookup<NativeFunction<sqlite3_column_name_native_t>>(
            'sqlite3_column_name')
        .asFunction();
    sqlite3_column_type = sqlite
        .lookup<NativeFunction<sqlite3_column_type_native_t>>(
            'sqlite3_column_type')
        .asFunction();
    sqlite3_column_double = sqlite
        .lookup<NativeFunction<sqlite3_column_double_native_t>>(
            'sqlite3_column_double')
        .asFunction();
    sqlite3_column_int64 = sqlite
        .lookup<NativeFunction<sqlite3_column_int64_native_t>>(
            'sqlite3_column_int64')
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
