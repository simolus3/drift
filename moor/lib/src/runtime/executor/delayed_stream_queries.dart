import 'package:meta/meta.dart';
import 'package:moor/src/runtime/api/runtime_api.dart';

import 'stream_queries.dart';

/// Version of [StreamQueryStore] that delegates work to an asynchronously-
/// available delegate.
/// This class is internal and should not be exposed to moor users. It's used
/// through a delayed database connection.
@internal
class DelayedStreamQueryStore implements StreamQueryStore {
  late Future<StreamQueryStore> _delegate;
  StreamQueryStore? _resolved;

  /// Creates a [StreamQueryStore] that will work after [delegate] is
  /// available.
  DelayedStreamQueryStore(Future<StreamQueryStore> delegate) {
    _delegate = delegate.then((value) => _resolved = value);
  }

  @override
  Future<void> close() async => (await _delegate).close();

  @override
  void handleTableUpdates(Set<TableUpdate> updates) {
    _resolved?.handleTableUpdates(updates);
  }

  @override
  void markAsClosed(QueryStream stream, Function() whenRemoved) {
    throw UnimplementedError('The stream will call this on the delegate');
  }

  @override
  void markAsOpened(QueryStream stream) {
    throw UnimplementedError('The stream will call this on the delegate');
  }

  @override
  Stream<List<Map<String, Object?>>> registerStream(
      QueryStreamFetcher fetcher) {
    return Stream.fromFuture(_delegate)
        .asyncExpand((resolved) => resolved.registerStream(fetcher))
        .asBroadcastStream();
  }

  @override
  Stream<Set<TableUpdate>> updatesForSync(TableUpdateQuery query) {
    return Stream.fromFuture(_delegate)
        .asyncExpand((resolved) => resolved.updatesForSync(query))
        .asBroadcastStream();
  }
}
