import 'package:meta/meta.dart';

import '../database/connection_user.dart';
import 'store.dart';
import 'update_rules.dart';

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
  Stream<T> registerStream<T extends Object>(
      QueryStreamFetcher<T> fetcher, DatabaseConnectionUser database) {
    return _delegateStream((store) => store.registerStream(fetcher, database));
  }

  @override
  Stream<Set<TableUpdate>> updatesForSync(TableUpdateQuery query) {
    return _delegateStream((store) => store.updatesForSync(query));
  }
}
