/// Moor implementation using `package:sqlite3/`.
///
/// When using a [NativeDatabase], you need to ensure that `sqlite3` is
/// available when running your app. For mobile Flutter apps, you can simply
/// depend on the `sqlite3_flutter_libs` package to ship the latest sqlite3
/// version with your app.
/// For more information other platforms, see [other engines](https://drift.simonbinder.eu/docs/other-engines/vm/).
library moor.ffi;

import 'src/ffi/database.dart';

export 'package:sqlite3/sqlite3.dart' show SqliteException;
export 'src/ffi/database.dart';
