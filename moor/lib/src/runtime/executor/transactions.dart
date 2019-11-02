import 'package:moor/moor.dart';
import 'package:moor/src/runtime/executor/stream_queries.dart';

/// Runs multiple statements transactionally.
///
/// Moor users should use [QueryEngine.transaction] to use this api.
class Transaction extends DatabaseConnectionUser with QueryEngine {
  /// Constructs a transaction executor from the [other] user and the underlying
  /// [executor].
  Transaction(DatabaseConnectionUser other, TransactionExecutor executor)
      : super.delegate(
          other,
          executor: executor,
          streamQueries: _TransactionStreamStore(other.streamQueries),
        );

  /// Instructs the underlying executor to execute this instructions. Batched
  /// table updates will also be send to the stream query store.
  Future complete() async {
    final streams = streamQueries as _TransactionStreamStore;
    await (executor as TransactionExecutor).send();

    await streams.dispatchUpdates();
  }
}

/// Stream query store that doesn't allow creating new streams and dispatches
/// updates to the outer stream query store when the transaction is completed.
class _TransactionStreamStore extends StreamQueryStore {
  final StreamQueryStore parent;
  final Set<TableInfo> affectedTables = <TableInfo>{};

  _TransactionStreamStore(this.parent);

  @override
  Stream<T> registerStream<T>(QueryStreamFetcher<T> statement) {
    throw StateError('Streams cannot be created inside a transaction. See the '
        'documentation of GeneratedDatabase.transaction for details.');
  }

  @override
  Future handleTableUpdates(Set<TableInfo> tables) {
    affectedTables.addAll(tables);
    return Future.value(null);
  }

  Future dispatchUpdates() {
    return parent.handleTableUpdates(affectedTables);
  }
}

/// Special query engine to run the [MigrationStrategy.beforeOpen] callback.
///
/// To use this api, moor users should use the [MigrationStrategy.beforeOpen]
/// parameter inside the [GeneratedDatabase.migration] getter.
class BeforeOpenRunner extends DatabaseConnectionUser with QueryEngine {
  /// Creates a [BeforeOpenRunner] from the [database] and the special
  /// [executor] running the queries.
  BeforeOpenRunner(DatabaseConnectionUser database, QueryExecutor executor)
      : super.delegate(database, executor: executor);
}
