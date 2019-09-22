/// Utils to open a [DynamicLibrary] on platforms that aren't supported by
/// `moor_ffi` by default.
library open_helper;

import 'dart:ffi';

export 'src/load_library.dart';
