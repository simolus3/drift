/// Utils to open a [DynamicLibrary] on platforms that aren't supported by
/// `moor_ffi` by default.
@Deprecated('Consider migrating to package:sqlite3/open.dart')
library open_helper;

import 'dart:ffi';

export 'src/load_library.dart';
