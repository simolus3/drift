import 'package:moor/moor.dart';
import 'package:moor/src/runtime/executor/stream_queries.dart';

/// Used internally by moor.
class BeforeOpenEngine extends DatabaseConnectionUser with QueryEngine {
  BeforeOpenEngine(DatabaseConnectionUser other, QueryExecutor executor)
      : super.delegate(
          other,
          executor: executor,
          streamQueries: _IgnoreStreamQueries(),
        );
}

class _IgnoreStreamQueries extends StreamQueryStore {
  @override
  Stream<T> registerStream<T>(QueryStreamFetcher<T> statement) {
    throw StateError('Streams cannot be created inside a transaction. See the '
        'documentation of GeneratedDatabase.transaction for details.');
  }

  @override
  Future handleTableUpdates(Set<TableInfo> tables) {
    return Future.value(null);
  }
}
