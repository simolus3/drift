import 'package:drift/drift.dart';
import 'package:mockito/mockito.dart';

export 'database_stub.dart'
    if (dart.library.ffi) 'database_vm.dart'
    if (dart.library.js) 'database_web.dart';
export 'matchers.dart';
export 'mocks.dart';

GenerationContext stubContext({DriftDatabaseOptions? options}) {
  return GenerationContext(options ?? DriftDatabaseOptions(), _NullDatabase());
}

class _NullDatabase extends GeneratedDatabase {
  _NullDatabase() : super(_NullExecutor());

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables =>
      throw UnsupportedError('stub');

  @override
  int get schemaVersion => throw UnsupportedError('stub!');
}

class _NullExecutor extends Fake implements QueryExecutor {}
