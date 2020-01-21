// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

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
