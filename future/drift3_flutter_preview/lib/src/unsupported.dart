import 'package:drift3/drift.dart';
import 'package:drift_sqlite/drift_sqlite.dart';

import 'connect.dart';

/// Stub
DriftConnection driftDatabase({
  required String name,
  required SqliteOptions dialectOptions,
  DriftWebOptions? web,
  DriftNativeOptions? native,
}) {
  throw UnsupportedError(
    'driftDatabase() is not implemented on this platform because neither '
    '`dart:ffi` nor `dart:js_interop` are available.',
  );
}
