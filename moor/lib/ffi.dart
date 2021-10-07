/// Moor implementation using `package:sqlite3/`.
///
/// When using a [VmDatabase], you need to ensure that `sqlite3` is available
/// when running your app. For mobile Flutter apps, you can simply depend on the
/// `sqlite3_flutter_libs` package to ship the latest sqlite3 version with your
/// app.
/// For more information other platforms, see [other engines](https://moor.simonbinder.eu/docs/other-engines/vm/).
library moor.ffi;

import 'package:drift/native.dart';

export 'package:drift/native.dart' hide NativeDatabase;

/// A moor database implementation based on `dart:ffi`, running directly in a
/// Dart VM or an AOT compiled Dart/Flutter application.
typedef VmDatabase = NativeDatabase;
