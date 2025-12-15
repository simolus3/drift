import 'dart:async';
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../../utils/cancellation_zone.dart';
import 'update_rules.dart';

const _listEquality = ListEquality<Object?>();

/// Defines interfaces for running streams that refresh on table updates, as
/// well as dispatching table updates.
abstract base class StreamQueryStore {
  /// Active streams with a [QueryStreamFetcher.key], used to de-duplicate them.
  final Map<StreamKey, QueryStream> _activeKeyStreams = {};
  final HashSet<StreamKey?> _keysPendingRemoval = HashSet<StreamKey?>();

  final bool _closeStreamsSynchronously;
  bool _isShuttingDown = false;

  // we track pending timers since Flutter throws an exception when timers
  // remain after a test run.
  final Set<Completer<void>> _pendingTimers = {};

  /// [closeStreamsSynchronously] controls whether resources with a stream
  /// should be closed synchronously after all listeners have cancelled their
  /// stream subscriptions. By default,
  StreamQueryStore({bool closeStreamsSynchronously = false})
    : _closeStreamsSynchronously = closeStreamsSynchronously;

  /// Whether this query store is shutting down (that is, [close] has been
  /// called).
  @protected
  bool get isShuttingDown => _isShuttingDown;

  /// Creates a stream that emits updates synchronously if they match [query].
  Stream<Set<TableUpdate>> updatesForSync(TableUpdateQuery query);

  /// Handles updates on a given table by re-executing all queries that read
  /// from that table.
  void handleTableUpdates(Set<TableUpdate> updates);

  /// Creates a new stream from a select statement expressed through [fetcher].
  Stream<T> registerStream<T extends Object>(QueryStreamFetcher<T> fetcher) {
    final key = fetcher.key;

    if (key != null) {
      final cached = _activeKeyStreams[key];
      if (cached != null) {
        return cached._stream as Stream<T>;
      }
    }

    // no cached instance found, create a new stream and register it so later
    // requests with the same key can be cached.
    final stream = QueryStream<T>(fetcher, this);
    // todo this adds the stream to a map, where it will only be removed when
    // somebody listens to it and later calls .cancel(). Failing to do so will
    // cause a memory leak. Is there any way we can work around it? Perhaps a
    // weak reference with an Expando could help.
    _markAsOpened(stream);

    return stream._stream;
  }

  /// Closes this instance.
  ///
  /// This will also end all streams registered with [registerStream].
  @mustCallSuper
  Future<void> close() async {
    _isShuttingDown = true;

    for (final stream in _activeKeyStreams.values) {
      await stream.close();
    }

    while (_pendingTimers.isNotEmpty) {
      await _pendingTimers.first.future;
    }

    _activeKeyStreams.clear();
  }

  void _markAsClosed(QueryStream stream, void Function() whenRemoved) {
    if (_isShuttingDown) return;

    final key = stream._fetcher.key;
    if (_closeStreamsSynchronously) {
      whenRemoved();
      _activeKeyStreams.remove(key);
      return;
    }

    _keysPendingRemoval.add(key);

    // sync because it's only triggered after the timer
    final completer = Completer<void>.sync();
    _pendingTimers.add(completer);

    // Hey there! If you're sent here because your Flutter tests fail, please
    // call and await Database.close() in your Flutter widget tests!
    // Drift uses timers internally so that after you stopped listening to a
    // stream, it can keep its cache just a bit longer. When you listen to
    // streams a lot, this helps reduce duplicate statements, especially with
    // Flutter's StreamBuilder.
    Timer.run(() {
      completer.complete();
      _pendingTimers.remove(completer);

      // if no other subscriber was found during this event iteration, remove
      // the stream from the cache.
      if (_keysPendingRemoval.contains(key)) {
        _keysPendingRemoval.remove(key);
        _activeKeyStreams.remove(key);
        whenRemoved();
      }
    });
  }

  void _markAsOpened(QueryStream stream) {
    final key = stream._fetcher.key;

    if (key != null) {
      _keysPendingRemoval.remove(key);
      _activeKeyStreams[key] = stream;
    }
  }
}

/// Representation of a select statement that knows from which tables the
/// statement is reading its data and how to execute the query.
class QueryStreamFetcher<Rows extends Object> {
  /// Table updates that will affect this stream.
  ///
  /// If any of these tables changes, the stream must fetch its data again.
  final TableUpdateQuery readsFrom;

  /// Key that can be used to check whether two fetchers will yield the same
  /// result when operating on the same data.
  ///
  /// When not null, [Rows] must be `List<Map<String, Object?>>` (the most
  /// common form used for all queries except for manager queries with
  /// prefetches).
  final StreamKey? key;

  /// A function that asynchronously prepares the session for running streams.
  ///
  /// Unlike [fetchData], this is not necessarily called multiple times and
  /// can't be cancelled.
  final FutureOr<void> Function() prepare;

  /// Function that asynchronously fetches the latest set of data.
  final Future<Rows> Function() fetchData;

  /// @nodoc
  QueryStreamFetcher({
    required this.readsFrom,
    this.key,
    required this.prepare,
    required this.fetchData,
  });
}

/// Key that uniquely identifies a select statement. If two keys created from
/// two select statements are equal, the statements are equal as well.
///
/// As two equal statements always yield the same result when operating on the
/// same data, this can make streams more efficient as we can return the same
/// stream for two equivalent queries.
final class StreamKey {
  /// The SQL statement this stream runs.
  final String sql;

  /// Variables passed to [sql].
  final List<dynamic> variables;

  /// @nodoc
  StreamKey(this.sql, this.variables);

  @override
  int get hashCode {
    return Object.hash(sql, _listEquality.hash(variables));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is StreamKey &&
            other.sql == sql &&
            _listEquality.equals(other.variables, variables));
  }
}

@internal
final class QueryStream<Rows extends Object> {
  final QueryStreamFetcher<Rows> _fetcher;
  final StreamQueryStore _store;

  final List<_QueryStreamListener<Rows>> _listeners = [];
  int _pausedListeners = 0;

  int get _activeListeners => _listeners.length - _pausedListeners;

  // We're using a Stream.multi to implement a broadcast-ish stream with per-
  // subscription pauses.
  late final Stream<Rows> _stream = Stream.multi((listener) {
    final queryListener = _QueryStreamListener<Rows>(listener);

    if (_isClosed) {
      listener.close();
      return;
    }

    // When this callback is called we have a new listener, so invoke the
    // handler now.
    _listeners.add(queryListener);
    _onListenOrResume(queryListener);

    listener
      ..onPause = () {
        assert(!queryListener.isPaused);
        queryListener.isPaused = true;
        _pausedListeners++;

        _onCancelOrPause();
      }
      ..onCancel = () {
        if (queryListener.isPaused) {
          _pausedListeners--;
        }

        _listeners.remove(queryListener);
        _onCancelOrPause();
      }
      ..onResume = () {
        assert(queryListener.isPaused);
        queryListener.isPaused = false;
        _pausedListeners--;

        _onListenOrResume(queryListener);
      };
  }, isBroadcast: true);

  StreamSubscription<Set<TableUpdate>>? _tablesChangedSubscription;

  Rows? _lastData;
  final List<CancellationToken<void>> _runningOperations = [];
  bool _isClosed = false;

  bool get hasKey => _fetcher.key != null;

  QueryStream(this._fetcher, this._store);

  void _onListenOrResume(_QueryStreamListener<Rows> newListener) {
    // First listener, start fetching data
    _store._markAsOpened(this);

    // fetch new data whenever any table referenced in this stream updates.
    // It could be that we have an outstanding subscription when the
    // stream was closed but another listener attached quickly enough. In that
    // case we don't have to re-send the query
    if (_tablesChangedSubscription == null) {
      // first listener added, fetch query
      fetchAndEmitData();

      _tablesChangedSubscription = _store
          .updatesForSync(_fetcher.readsFrom)
          .listen((_) {
            // table has changed, invalidate cache
            _lastData = null;

            // If we have in-flight queries right now, we can no longer guarantee
            // that their results reflect these changes already. So we have to
            // cancel them and ignore their results.
            _cancelRunningQueries();

            // It could be that we have no active, but some paused listeners. In
            // that case, we still want to invalidate cached data but there's no
            // point in fetching new data now. We'll load the query again after
            // a listener unpauses.
            if (_activeListeners > 0) {
              fetchAndEmitData();
            }
          });
    } else if (_lastData == null) {
      if (_runningOperations.isEmpty) {
        // We have a new listener, no cached data and we're not in the process
        // of fetching data either. Let's run the query then!
        fetchAndEmitData();
      }
    } else {
      // Push the current snapshot of pending data to the listener
      newListener.add(_lastData!);
    }
  }

  void _onCancelOrPause() {
    if (_listeners.isEmpty) {
      // Last listener has stopped listening properly (not just a pause)
      _store._markAsClosed(this, () {
        // last listener gone, dispose
        _tablesChangedSubscription?.cancel();

        // we don't listen for table updates anymore, and we're guaranteed to
        // re-fetch data after a new listener comes in. We can't know if the
        // table was updated in the meantime, but let's delete the cached data
        // just in case.
        _lastData = null;
        _tablesChangedSubscription = null;

        _cancelRunningQueries();
      });
    }
  }

  void _cancelRunningQueries() {
    for (final op in _runningOperations) {
      op.cancel();
    }
    _runningOperations.clear();
  }

  Future<void> fetchAndEmitData() async {
    final operation = CancellationToken<Rows>();
    _runningOperations.add(operation);

    try {
      // Make sure the database is ready to be used before running the query in
      // a cancellation zone. Opening the database should never be cancelled.
      await _fetcher.prepare();

      if (operation.isCancelled) return;
      runCancellable<Rows>(_fetcher.fetchData, token: operation);
      final data = await operation.resultOrNullIfCancelled;
      if (data == null) return;

      _lastData = data;
      for (final listener in _listeners) {
        if (!listener.isPaused) {
          listener.add(data);
        }
      }
    } catch (e, s) {
      for (final listener in _listeners) {
        if (!listener.isPaused) {
          listener.controller.addError(e, s);
        }
      }
    } finally {
      _runningOperations.remove(operation);
    }
  }

  Future<void> close() async {
    _isClosed = true;

    final listenersDone = Future.wait([
      for (final listener in _listeners) listener.controller.close(),
    ]);
    _listeners.clear();
    await listenersDone;
  }
}

class _QueryStreamListener<Rows> {
  final MultiStreamController<Rows> controller;
  Rows? lastEvent;
  bool isPaused = false;

  _QueryStreamListener(this.controller);

  void add(Rows row) {
    // Don't emit events that have already been dispatched to this listener.
    if (!identical(row, lastEvent)) {
      lastEvent = row;
      controller.add(row);
    }
  }
}
