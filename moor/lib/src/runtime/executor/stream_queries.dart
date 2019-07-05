import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:moor/moor.dart';
import 'package:moor/src/utils/start_with_value_transformer.dart';

const _listEquality = ListEquality<dynamic>();

/// Representation of a select statement that knows from which tables the
/// statement is reading its data and how to execute the query.
class QueryStreamFetcher<T> {
  /// The set of tables this query reads from. If any of these tables changes,
  /// the stream must fetch its data again.
  final Set<TableInfo> readsFrom;

  /// Key that can be used to check whether two fetchers will yield the same
  /// result when operating on the same data.
  final StreamKey key;

  /// Function that asynchronously fetches the latest set of data.
  final Future<T> Function() fetchData;

  QueryStreamFetcher(
      {@required this.readsFrom, this.key, @required this.fetchData});
}

/// Key that uniquely identifies a select statement. If two keys created from
/// two select statements are equal, the statements are equal as well.
///
/// As two equal statements always yield the same result when operating on the
/// same data, this can make streams more efficient as we can return the same
/// stream for two equivalent queries.
class StreamKey {
  final String sql;
  final List<dynamic> variables;

  /// Used to differentiate between custom streams, which return a [QueryRow],
  /// and regular streams, which return an instance of a generated data class.
  final Type returnType;

  StreamKey(this.sql, this.variables, this.returnType);

  @override
  int get hashCode {
    return (sql.hashCode * 31 + _listEquality.hash(variables)) * 31 +
        returnType.hashCode;
  }

  @override
  bool operator ==(other) {
    return identical(this, other) ||
        (other is StreamKey &&
            other.sql == sql &&
            _listEquality.equals(other.variables, variables) &&
            other.returnType == returnType);
  }
}

/// Keeps track of active streams created from [SimpleSelectStatement]s and updates
/// them when needed.
class StreamQueryStore {
  final List<QueryStream> _activeStreamsWithoutKey = [];
  final Map<StreamKey, QueryStream> _activeKeyStreams = {};

  StreamQueryStore();

  Iterable<QueryStream> get _activeStreams {
    return _activeKeyStreams.values.followedBy(_activeStreamsWithoutKey);
  }

  /// Creates a new stream from the select statement.
  Stream<T> registerStream<T>(QueryStreamFetcher<T> fetcher) {
    final key = fetcher.key;

    if (key == null) {
      final stream = QueryStream(fetcher, this);
      _activeStreamsWithoutKey.add(stream);
      return stream.stream;
    } else {
      final stream = _activeKeyStreams.putIfAbsent(key, () {
        return QueryStream<T>(fetcher, this);
      });

      return (stream as QueryStream<T>).stream;
    }
  }

  /// Handles updates on a given table by re-executing all queries that read
  /// from that table.
  Future<void> handleTableUpdates(Set<TableInfo> tables) async {
    final activeStreams = List<QueryStream>.from(_activeStreams);
    final updatedNames = tables.map((t) => t.actualTableName).toSet();

    final affectedStreams = activeStreams.where((stream) {
      return stream._fetcher.readsFrom.any((table) {
        return updatedNames.contains(table.actualTableName);
      });
    });

    for (var stream in affectedStreams) {
      await stream.fetchAndEmitData();
    }
  }

  void markAsClosed(QueryStream stream) {
    final key = stream._fetcher.key;
    if (key == null) {
      _activeStreamsWithoutKey.remove(stream);
    } else {
      _activeKeyStreams.remove(key);
    }
  }
}

class QueryStream<T> {
  final QueryStreamFetcher<T> _fetcher;
  final StreamQueryStore _store;

  StreamController<T> _controller;

  T _lastData;

  Stream<T> get stream {
    _controller ??= StreamController.broadcast(
      onListen: _onListen,
      onCancel: _onCancel,
    );

    return _controller.stream.transform(StartWithValueTransformer(_cachedData));
  }

  QueryStream(this._fetcher, this._store);

  /// Called when we have a new listener, makes the stream query behave similar
  /// to an `BehaviorSubject` from rxdart.
  T _cachedData() => _lastData;

  void _onListen() {
    // first listener added, fetch query
    fetchAndEmitData();
  }

  void _onCancel() {
    // last listener gone, dispose
    _controller.close();
    // todo this removes the stream from the list so that it can be garbage
    // collected. When a stream is never listened to, we have a memory leak as
    // this will never be called. Maybe an Expando (which uses weak references)
    // can save us here?
    _store.markAsClosed(this);
  }

  Future<void> fetchAndEmitData() async {
    // Fetch data if it's needed, publish that data if it's possible.
    if (!_controller.hasListener) return;

    final data = await _fetcher.fetchData();
    _lastData = data;

    if (!_controller.isClosed) {
      _controller.add(data);
    }
  }
}
