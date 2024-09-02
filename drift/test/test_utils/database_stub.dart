import 'package:drift/drift.dart';
import 'package:sqlite3/common.dart';

Version get sqlite3Version {
  return throw UnsupportedError('Stub, should resolve to web or vm');
}

/// Serializes and then deserializes [source] as if it were sent to a remote
/// execution context.
///
/// This is a no-op on VM platforms, but calls `jsify()` followed by `dartify()`
/// for web tests.
Object? transportRoundtrip(Object? source) {
  throw UnsupportedError('Stub, should resolve to web or vm');
}

DatabaseConnection testInMemoryDatabase() {
  throw UnsupportedError('Stub, should resolve to web or vm');
}
