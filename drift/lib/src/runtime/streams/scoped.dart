import 'package:meta/meta.dart';

import 'store.dart';
import 'store_impl.dart';
import 'update_rules.dart';

/// A [StreamQueryStore] that tracks updates locally and forwards them to a
/// [parent] store after closing.
///
/// This is the stream query store used for transactions. Streams created in
/// transactions reflect changes made within the transaction, but close as the
/// transaction completes.
@internal
final class ScopedStreamQueryStore extends LocalStreamQueryStore {
  final StreamQueryStore parent;

  /// All table updates collected within this scope (that haven't yet been
  /// forwarded to the [parent] store).
  final Set<TableUpdate> affectedTables = <TableUpdate>{};

  ScopedStreamQueryStore(this.parent);

  @override
  void handleTableUpdates(Set<TableUpdate> updates) {
    super.handleTableUpdates(updates);
    affectedTables.addAll(updates);
  }

  @override
  Future<void> close({bool forwardUpdates = true}) async {
    await super.close();
    if (forwardUpdates) {
      parent.handleTableUpdates(affectedTables);
    }
  }
}
