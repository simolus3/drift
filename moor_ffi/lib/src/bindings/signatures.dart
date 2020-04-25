// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import '../ffi/blob.dart';

import 'types.dart';

typedef sqlite3_open_v2_native_t = Int32 Function(Pointer<CBlob> filename,
    Pointer<Pointer<Database>> ppDb, Int32 flags, Pointer<CBlob> vfs);

typedef sqlite3_close_v2_native_t = Int32 Function(Pointer<Database> database);

typedef sqlite3_free_native = Void Function(Pointer<Void> pointer);

typedef sqlite3_prepare_v2_native_t = Int32 Function(
    Pointer<Database> database,
    Pointer<CBlob> query,
    Int32 nbytes,
    Pointer<Pointer<Statement>> statementOut,
    Pointer<Pointer<CBlob>> tail);

typedef sqlite3_exec_native = Int32 Function(
    Pointer<Database> database,
    Pointer<CBlob> query,
    Pointer<Void> callback,
    Pointer<Void> firstCbArg,
    Pointer<Pointer<CBlob>> errorOut);

typedef sqlite3_step_native_t = Int32 Function(Pointer<Statement> statement);

typedef sqlite3_reset_native_t = Int32 Function(Pointer<Statement> statement);

typedef sqlite3_finalize_native_t = Int32 Function(
    Pointer<Statement> statement);

typedef sqlite3_extended_errcode_native_t = Int32 Function(
    Pointer<Database> database);

typedef sqlite3_errstr_native_t = Pointer<CBlob> Function(Int32 error);

typedef sqlite3_errmsg_native_t = Pointer<CBlob> Function(
    Pointer<Database> database);

typedef sqlite3_extended_result_codes_t = Int32 Function(
    Pointer<Database> database, Int32 onOff);

typedef sqlite3_column_count_native_t = Int32 Function(
    Pointer<Statement> statement);

typedef sqlite3_column_name_native_t = Pointer<CBlob> Function(
    Pointer<Statement> statement, Int32 columnIndex);

typedef sqlite3_column_type_native_t = Int32 Function(
    Pointer<Statement> statement, Int32 columnIndex);

typedef sqlite3_column_double_native_t = Double Function(
    Pointer<Statement> statement, Int32 columnIndex);

typedef sqlite3_column_int64_native_t = Int64 Function(
    Pointer<Statement> statement, Int32 columnIndex);

typedef sqlite3_column_text_native_t = Pointer<CBlob> Function(
    Pointer<Statement> statement, Int32 columnIndex);

typedef sqlite3_column_blob_native_t = Pointer<CBlob> Function(
    Pointer<Statement> statement, Int32 columnIndex);

typedef sqlite3_column_bytes_native_t = Int32 Function(
    Pointer<Statement> statement, Int32 columnIndex);

typedef sqlite3_changes_native = Int32 Function(Pointer<Database> database);
typedef sqlite3_last_insert_rowid_native = Int64 Function(
    Pointer<Database> database);

typedef sqlite3_bind_double_native = Int32 Function(
    Pointer<Statement> statement, Int32 columnIndex, Double value);
typedef sqlite3_bind_int64_native = Int32 Function(
    Pointer<Statement> statement, Int32 columnIndex, Int64 value);
typedef sqlite3_bind_text_native = Int32 Function(
    Pointer<Statement> statement,
    Int32 columnIndex,
    Pointer<CBlob> value,
    Int32 length,
    Pointer<Void> callback);
typedef sqlite3_bind_blob_native = Int32 Function(
    Pointer<Statement> statement,
    Int32 columnIndex,
    Pointer<CBlob> value,
    Int32 length,
    Pointer<Void> callback);
typedef sqlite3_bind_null_native = Int32 Function(
    Pointer<Statement> statement, Int32 columnIndex);

typedef sqlite3_function_handler = Void Function(
    Pointer<FunctionContext> context,
    Int32 argCount,
    Pointer<Pointer<SqliteValue>> args);

typedef sqlite3_function_finalizer = Void Function(
    Pointer<FunctionContext> context);

typedef sqlite3_finalizer = Void Function(Pointer<Void> ptr);

typedef sqlite3_create_function_v2_native = Int32 Function(
  Pointer<Database> db,
  Pointer<Uint8> zFunctionName,
  Int32 nArg,
  Int32 eTextRep,
  Pointer<Void> pApp,
  Pointer<NativeFunction<sqlite3_function_handler>> xFunc,
  Pointer<NativeFunction<sqlite3_function_handler>> xStep,
  Pointer<NativeFunction<sqlite3_function_finalizer>> xDestroy,
  Pointer<NativeFunction<sqlite3_finalizer>> finalizePApp,
);

typedef sqlite3_value_blob_native = Pointer<CBlob> Function(
    Pointer<SqliteValue> value);
typedef sqlite3_value_double_native = Double Function(
    Pointer<SqliteValue> value);
typedef sqlite3_value_int64_native = Int64 Function(Pointer<SqliteValue> value);
typedef sqlite3_value_text_native = Pointer<CBlob> Function(
    Pointer<SqliteValue> value);
typedef sqlite3_value_bytes_native = Int32 Function(Pointer<SqliteValue> value);
typedef sqlite3_value_type_native = Int32 Function(Pointer<SqliteValue> value);

typedef sqlite3_result_null_native = Void Function(
    Pointer<FunctionContext> context);
typedef sqlite3_result_double_native = Void Function(
    Pointer<FunctionContext> context, Double value);
typedef sqlite3_result_int64_native = Void Function(
    Pointer<FunctionContext> context, Int64 value);
typedef sqlite3_result_error_native = Void Function(
    Pointer<FunctionContext> context, Pointer<CBlob> char, Int32 len);
