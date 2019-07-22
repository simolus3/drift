/// A version of moor that runs on the Dart VM by integrating sqlite3 with
/// ffi.
@experimental
library moor_vm;

import 'dart:async';
import 'dart:io';

import 'package:meta/meta.dart';
import 'backends.dart';
import 'moor.dart';

import 'src/vm/api/database.dart';

part 'src/vm/vm_database.dart';
