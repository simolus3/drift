import 'package:drift/drift.dart';
import 'package:drift/dialect/sqlite.dart';
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

DriftDatabaseImplementation createConnection(
  DriftRootSession session, {
  StreamQueryStore? streams,
  DriftDialect? dialect,
}) {
  return DriftDatabaseImplementation(
    dialect: dialect ?? const SqliteDialect(),
    openConnection: () async => session,
    streamQueries: streams,
  );
}

/*
class PretendDialectInterceptor extends QueryInterceptor {
  final SqlDialect _dialect;

  PretendDialectInterceptor(this._dialect);

  @override
  SqlDialect dialect(QueryExecutor executor) {
    return _dialect;
  }
}
*/
