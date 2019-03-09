import 'dart:async';

import 'package:moor/moor.dart';

/// Internal interface to mark classes that respond to table changes
abstract class TableChangeListener<T> {
  /// Called to check if this listener should update after the table with the
  /// given name has changed.
  bool isAffectedBy(String table);

  /// Called to reload data from the table after it has changed.
  Future<T> handleDataChanged();
}

/// Keeps track of active streams created from [SelectStatement]s and updates
/// them when needed.
class StreamQueryStore {
  final List<_QueryStream> _activeStreams = [];

  // todo cache streams (return same instance for same sql + variables)

  StreamQueryStore();

  /// Creates a new stream from the select statement.
  Stream<List<T>> registerStream<T>(TableChangeListener<List<T>> statement) {
    final stream = _QueryStream(statement, this);
    _activeStreams.add(stream);
    return stream.stream;
  }

  /// Handles updates on a given table by re-executing all queries that read
  /// from that table.
  Future<void> handleTableUpdates(String table) async {
    final affectedStreams =
        _activeStreams.where((stream) => stream.isAffectedByTableChange(table));

    for (var stream in affectedStreams) {
      await stream.fetchAndEmitData();
    }
  }

  void _markAsClosed(_QueryStream stream) {
    _activeStreams.remove(stream);
  }
}

class _QueryStream<T> {
  final TableChangeListener<T> listener;
  final StreamQueryStore _store;

  StreamController<T> _controller;

  Stream<T> get stream {
    _controller ??= StreamController.broadcast(
      onListen: _onListen,
      onCancel: _onCancel,
    );

    return _controller.stream;
  }

  _QueryStream(this.listener, this._store);

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
    _store._markAsClosed(this);
  }

  Future<void> fetchAndEmitData() async {
    // Fetch data if it's needed, publish that data if it's possible.
    if (!_controller.hasListener) return;

    final data = await listener.handleDataChanged();

    if (!_controller.isClosed) {
      _controller.add(data);
    }
  }

  bool isAffectedByTableChange(String table) => listener.isAffectedBy(table);
}
