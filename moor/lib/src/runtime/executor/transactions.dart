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
    await (executor as TransactionExecutor).send();
  }

  /// Closes all streams created in this transactions and applies table updates
  /// to the main stream store.
  Future<void> disposeChildStreams() async {
    final streams = streamQueries as _TransactionStreamStore;
    await streams._dispatchAndClose();
  }
}

/// Stream query store that doesn't allow creating new streams and dispatches
/// updates to the outer stream query store when the transaction is completed.
class _TransactionStreamStore extends StreamQueryStore {
  final StreamQueryStore parent;

  final Set<String> affectedTables = <String>{};
  final Set<QueryStream> _queriesWithoutKey = {};

  _TransactionStreamStore(this.parent);

  @override
  void handleTableUpdatesByName(Set<String> tables) {
    affectedTables.addAll(tables);
    super.handleTableUpdatesByName(tables);
  }

  // Override lifecycle hooks for each stream. The regular StreamQueryStore
  // keeps track of created streams if they have a key. It also takes care of
  // closing the underlying stream controllers when calling close(), which we
  // do.
  // However, it doesn't keep track of keyless queries, as those can't be
  // cached and keeping a reference would leak. A transaction is usually
  // completed quickly, so we can keep a list and close that too.

  @override
  void markAsOpened(QueryStream stream) {
    super.markAsOpened(stream);

    if (!stream.hasKey) {
      _queriesWithoutKey.add(stream);
    }
  }

  @override
  void markAsClosed(QueryStream stream, Function() whenRemoved) {
    super.markAsClosed(stream, whenRemoved);

    _queriesWithoutKey.add(stream);
  }

  Future _dispatchAndClose() async {
    parent.handleTableUpdatesByName(affectedTables);

    await super.close();
    for (final query in _queriesWithoutKey) {
      query.close();
    }
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
