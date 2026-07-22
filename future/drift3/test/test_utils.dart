import 'package:drift3/drift.dart';
import 'package:drift_sqlite/drift_sqlite.dart';

export 'test_utils/database_stub.dart'
    if (dart.library.ffi) 'test_utils/database_vm.dart'
    if (dart.library.js_interop) 'test_utils/database_web.dart';
export 'test_utils/matchers.dart';

DriftConnection createConnection(
  DriftSession session, {
  StreamQueryStore? streams,
  DriftDialectFactory? dialect,
}) {
  return DriftConnection(
    dialect: dialect ?? SqliteDialect.new,
    openConnection: () async => session,
    streamQueries: streams,
  );
}
