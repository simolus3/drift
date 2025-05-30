import 'package:drift/drift.dart';
import 'package:drift/sqlite3/dialect.dart';
import 'package:drift/src/runtime/streams/store.dart';
import 'package:mockito/annotations.dart';

export 'database_stub.dart'
    if (dart.library.ffi) 'database_vm.dart'
    if (dart.library.js_interop) 'database_web.dart';
export 'matchers.dart';
export 'mocks.dart';

@GenerateNiceMocks([
  MockSpec<StreamQueryStore>(as: #MockStreamQueries),
])
export 'test_utils.mocks.dart';

DriftConnection createConnection(
  DriftSession session, {
  StreamQueryStore? streams,
  DriftDialect? dialect,
}) {
  return DriftConnection(
    dialect: dialect ?? const SqliteDialect(),
    openConnection: () async => session,
    streamQueries: streams,
  );
}
