library moor;

import 'package:drift/drift.dart';

export 'package:drift/drift.dart';

/// Defines additional runtime behavior for moor. Changing the fields of this
/// class is rarely necessary.
@pragma('moor2drift', 'DriftRuntimeOptions')
typedef MoorRuntimeOptions = DriftRuntimeOptions;

/// Stores the [MoorRuntimeOptions] describing global moor behavior across
/// databases.
///
/// Note that is is adapting this behavior is rarely needed.
@pragma('moor2drift', 'driftRuntimeOptions')
MoorRuntimeOptions get moorRuntimeOptions => driftRuntimeOptions;

@pragma('moor2drift', 'driftRuntimeOptions')
set moorRuntimeOptions(MoorRuntimeOptions o) => driftRuntimeOptions = o;

/// For use by generated code in calculating hash codes. Do not use directly.
int $mrjc(int hash, int value) {
  // Jenkins hash "combine".
  hash = 0x1fffffff & (hash + value);
  hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
  return hash ^ (hash >> 6);
}

/// For use by generated code in calculating hash codes. Do not use directly.
int $mrjf(int hash) {
  // Jenkins hash "finish".
  hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
  hash = hash ^ (hash >> 11);
  return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
}
