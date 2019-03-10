import 'package:moor/moor.dart';
import 'package:moor/src/runtime/executor/stream_queries.dart';

class Transaction extends DatabaseConnectionUser with QueryEngine {
  Transaction(DatabaseConnectionUser other, TransactionExecutor executor)
      : super.delegate(
          other,
          executor: executor,
          streamQueries: _TransactionStreamStore(other.streamQueries),
        );

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
  final Set<String> affectedTables = <String>{};

  _TransactionStreamStore(this.parent);

  @override
  Stream<List<T>> registerStream<T>(TableChangeListener<List<T>> statement) {
    throw StateError('Streams cannot be created inside a transaction. See the '
        'documentation of GeneratedDatabase.transaction for details.');
  }

  @override
  Future handleTableUpdates(Set<String> tables) {
    affectedTables.addAll(tables);
    return Future.value(null);
  }

  Future dispatchUpdates() {
    return parent.handleTableUpdates(affectedTables);
  }
}
