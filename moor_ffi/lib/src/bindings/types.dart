// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:ffi';

import 'package:moor/moor.dart';

import '../ffi/blob.dart';
import '../ffi/utils.dart';
import 'bindings.dart';
import 'constants.dart';

// ignore_for_file: comment_references

/// Database Connection Handle
///
/// Each open SQLite database is represented by a pointer to an instance of
/// the opaque structure named "sqlite3".  It is useful to think of an sqlite3
/// pointer as an object.  The [sqlite3_open()], [sqlite3_open16()], and
/// [sqlite3_open_v2()] interfaces are its constructors, and [sqlite3_close()]
/// is its destructor.  There are many other interfaces (such as
/// [sqlite3_prepare_v2()], [sqlite3_create_function()], and
/// [sqlite3_busy_timeout()] to name but three) that are methods on an
class Database extends Struct {}

/// SQL Statement Object
///
/// An instance of this object represents a single SQL statement.
/// This object is variously known as a "prepared statement" or a
/// "compiled SQL statement" or simply as a "statement".
///
/// The life of a statement object goes something like this:
///
/// <ol>
/// <li> Create the object using [sqlite3_prepare_v2()] or a related
///      function.
/// <li> Bind values to [host parameters] using the sqlite3_bind_*()
///      interfaces.
/// <li> Run the SQL by calling [sqlite3_step()] one or more times.
/// <li> Reset the statement using [sqlite3_reset()] then go back
///      to step 2.  Do this zero or more times.
/// <li> Destroy the object using [sqlite3_finalize()].
/// </ol>
///
/// Refer to documentation on individual methods above for additional
/// information.
class Statement extends Struct {}

/// The context in which an SQL function executes is stored in this object.
/// A pointer to this object is always the first paramater to
/// application-defined SQL functions.
///
/// See also:
/// - https://www.sqlite.org/c3ref/context.html
class FunctionContext extends Struct {}

/// A value object in sqlite, which can represent all values that can be stored
/// in a database table.
class SqliteValue extends Struct {}

/// Extension to extract value from a [SqliteValue].
extension SqliteValuePointer on Pointer<SqliteValue> {
  /// Extracts the raw value from the object.
  ///
  /// Depending on the type of this value as set in sqlite, [value] returns
  ///  - a [String]
  ///  - a [Uint8List]
  ///  - a [int]
  ///  - a [double]
  ///  - `null`
  ///
  /// For texts and bytes, the value be copied.
  dynamic get value {
    final api = bindings;

    final type = api.sqlite3_value_type(this);
    switch (type) {
      case Types.SQLITE_INTEGER:
        return api.sqlite3_value_int64(this);
      case Types.SQLITE_FLOAT:
        return api.sqlite3_value_double(this);
      case Types.SQLITE_TEXT:
        final length = api.sqlite3_value_bytes(this);
        return api.sqlite3_value_text(this).readAsStringWithLength(length);
      case Types.SQLITE_BLOB:
        final length = api.sqlite3_value_bytes(this);
        if (length == 0) {
          // sqlite3_value_bytes returns a null pointer for non-null blobs with
          // a length of 0. Note that we can distinguish this from a proper null
          // by checking the type (which isn't SQLITE_NULL)
          return Uint8List(0);
        }
        return api.sqlite3_value_blob(this).readBytes(length);
      case Types.SQLITE_NULL:
      default:
        return null;
    }
  }
}

extension SqliteFunctionContextPointer on Pointer<FunctionContext> {
  void resultNull() {
    bindings.sqlite3_result_null(this);
  }

  void resultInt(int value) {
    bindings.sqlite3_result_int64(this, value);
  }

  void resultDouble(double value) {
    bindings.sqlite3_result_double(this, value);
  }

  void resultNum(num value) {
    if (value is int) {
      resultInt(value);
    } else if (value is double) {
      resultDouble(value);
    }

    throw AssertionError();
  }

  void resultBool(bool value) {
    resultInt(value ? 1 : 0);
  }

  void resultError(String message) {
    final encoded = Uint8List.fromList(utf8.encode(message));
    final ptr = CBlob.allocate(encoded);

    bindings.sqlite3_result_error(this, ptr, encoded.length);

    // Note that sqlite3_result_error makes a private copy of error message
    // before returning. Hence, we can deallocate the message here.
    ptr.free();
  }
}
