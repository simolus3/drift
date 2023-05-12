import 'package:drift/src/runtime/api/runtime_api.dart';
import 'package:meta/meta.dart';

import 'stream_queries.dart';

/// Version of [StreamQueryStore] that delegates work to an asynchronously-
/// available delegate.
/// This class is internal and should not be exposed to drift users. It's used
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
  void markAsClosed(QueryStream stream, void Function() whenRemoved) {
    throw UnimplementedError('The stream will call this on the delegate');
  }

  @override
  void markAsOpened(QueryStream stream) {
    throw UnimplementedError('The stream will call this on the delegate');
  }

  Stream<T> _delegateStream<T>(
      Stream<T> Function(StreamQueryStore store) createStream) {
    if (_resolved != null) {
      return createStream(_resolved!);
    } else {
      // Note: We can't use Stream.fromFuture(...).asyncExpand() since it is a
      // single-subscription stream.
      // `.asBroadcastStream()` doesn't work either because the internal caching
      // breaks query streams which need to know about live subscribers.
      return Stream.multi(
        (listener) async {
          final store = await _delegate;
          if (!listener.isClosed) {
            await listener.addStream(createStream(store));
          }
        },
        isBroadcast: true,
      );
    }
  }

  @override
  Stream<List<Map<String, Object?>>> registerStream(
      QueryStreamFetcher fetcher) {
    return _delegateStream((store) => store.registerStream(fetcher));
  }

  @override
  Stream<Set<TableUpdate>> updatesForSync(TableUpdateQuery query) {
    return _delegateStream((store) => store.updatesForSync(query));
  }
}
