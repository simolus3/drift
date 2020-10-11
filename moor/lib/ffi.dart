/// Moor implementation using `package:sqlite3/`.
///
/// When using a [VmDatabase], you need to ensure that `sqlite3` is available
/// when running your app. For mobile Flutter apps, you can simply depend on the
/// `sqlite3_flutter_libs` package to ship the latest sqlite3 version with your
/// app.
/// For more information other platforms, see [other engines](https://moor.simonbinder.eu/docs/other-engines/vm/).
library moor.ffi;

import 'package:moor/src/ffi/vm_database.dart';

export 'package:sqlite3/sqlite3.dart' show SqliteException;
export 'src/ffi/vm_database.dart';
