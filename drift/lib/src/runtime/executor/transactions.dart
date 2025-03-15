import 'package:drift/drift.dart';
import 'package:drift/src/runtime/executor/stream_queries.dart';
import 'package:meta/meta.dart';

/// Runs multiple statements transactionally.
@internal
class Transaction extends DatabaseConnectionUser {
  final DatabaseConnectionUser _parent;

  @override
  // ignore: invalid_use_of_visible_for_overriding_member
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

/// Special query engine to run the [MigrationStrategy.beforeOpen] callback.
///
/// To use this api, drift users should use the [MigrationStrategy.beforeOpen]
/// parameter inside the [GeneratedDatabase.migration] getter.
@internal
class BeforeOpenRunner extends DatabaseConnectionUser {
  final DatabaseConnectionUser _parent;

  @override
  // ignore: invalid_use_of_visible_for_overriding_member
  GeneratedDatabase get attachedDatabase => _parent.attachedDatabase;

  /// Creates a [BeforeOpenRunner] from a [DatabaseConnectionUser] and the
  /// special [executor] running the queries.
  BeforeOpenRunner(this._parent, QueryExecutor executor)
      : super.delegate(_parent, executor: executor);
}
