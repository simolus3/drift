import 'dart:async';

import 'store.dart';
import 'update_rules.dart';

/// A [StreamQueryStore] implementation backed by a stream controller and
/// explicit notifications via [handleTableUpdates].
final class InMemoryStreamQueryStore extends StreamQueryStore {
  // Why is this stream synchronous? We want to dispatch table updates before
  // the future from the query completes. This allows streams to invalidate
  // their cached data before the user can send another query.
  // There shouldn't be a problem as this stream is not exposed in any user-
  // facing api.
  final StreamController<Set<TableUpdate>> _tableUpdates =
      StreamController.broadcast(sync: true);

  /// @nodoc
  InMemoryStreamQueryStore({super.closeStreamsSynchronously});

  @override
  Stream<Set<TableUpdate>> updatesForSync(TableUpdateQuery query) {
    return _tableUpdates.stream
        .map((e) => e.where(query.matches).toSet())
        .where((e) => e.isNotEmpty);
  }

  @override
  void handleTableUpdates(Set<TableUpdate> updates) {
    if (isShuttingDown) return;
    _tableUpdates.add(updates);
  }
}
