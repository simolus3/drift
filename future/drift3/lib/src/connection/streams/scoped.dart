import 'package:meta/meta.dart';

import 'in_memory_store.dart';
import 'store.dart';
import 'update_rules.dart';

/// A [StreamQueryStore] that tracks updates locally and forwards them to a
/// [parent] store after closing.
///
/// This is the stream query store used for transactions. Streams created in
/// transactions reflect changes made within the transaction, but close as the
/// transaction completes.
@internal
final class ScopedStreamQueryStore extends StreamQueryStore {
  final StreamQueryStore parent;
  final InMemoryStreamQueryStore _inMemory = InMemoryStreamQueryStore();

  /// All table updates collected within this scope (that haven't yet been
  /// forwarded to the [parent] store).
  final Set<TableUpdate> affectedTables = <TableUpdate>{};

  ScopedStreamQueryStore(this.parent);

  @override
  void handleTableUpdates(Set<TableUpdate> updates) {
    _inMemory.handleTableUpdates(updates);
    affectedTables.addAll(updates);
  }

  @override
  Stream<Set<TableUpdate>> updatesForSync(TableUpdateQuery query) {
    return _inMemory.updatesForSync(query);
  }

  @override
  Future<void> close({bool forwardUpdates = true}) async {
    await _inMemory.close();
    await super.close();
    if (forwardUpdates) {
      parent.handleTableUpdates(affectedTables);
    }
  }
}
