import 'package:meta/meta.dart';
import 'package:moor/moor.dart';
import 'package:moor/src/runtime/executor/stream_queries.dart';

/// Runs multiple statements transactionally.
@internal
class Transaction extends DatabaseConnectionUser {
  final DatabaseConnectionUser _parent;

  @override
  GeneratedDatabase get attachedDatabase => _parent.attachedDatabase;

  /// Constructs a transaction executor from the [_parent] engine and the
  /// underlying [executor].
  Transaction(this._parent, TransactionExecutor executor)
      : super.delegate(
          _parent,
          executor: executor,
          streamQueries: _TransactionStreamStore(_parent.streamQueries),
        );

  /// Instructs the underlying executor to execute this instructions. Batched
  /// table updates will also be send to the stream query store.
  Future<void> complete() async {
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

  final Set<TableUpdate> affectedTables = <TableUpdate>{};
  final Set<QueryStream> _queriesWithoutKey = {};

  _TransactionStreamStore(this.parent);

  @override
  void handleTableUpdates(Set<TableUpdate> updates) {
    super.handleTableUpdates(updates);
    affectedTables.addAll(updates);
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
    parent.handleTableUpdates(affectedTables);

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
@internal
class BeforeOpenRunner extends DatabaseConnectionUser {
  final DatabaseConnectionUser _parent;

  @override
  GeneratedDatabase get attachedDatabase => _parent.attachedDatabase;

  /// Creates a [BeforeOpenRunner] from a [DatabaseConnectionUser] and the
  /// special [executor] running the queries.
  BeforeOpenRunner(this._parent, QueryExecutor executor)
      : super.delegate(_parent, executor: executor);
}
