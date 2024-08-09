import 'package:drift/drift.dart';

import 'connect.dart';

QueryExecutor driftDatabase({
  required String name,
  DriftWebOptions? web,
  DriftNativeOptions? native,
}) {
  throw UnsupportedError(
      'driftDatabase() is not implemented on this platform because neither `dart:ffi` nor ``');
}
