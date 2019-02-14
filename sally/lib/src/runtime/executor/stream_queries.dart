import 'dart:async';

import 'package:sally/sally.dart';

class StreamQueryStore {
  final List<_QueryStream> _activeStreams = const [];

  const StreamQueryStore();

  Stream<List<T>> registerStream<T>(SelectStatement<dynamic, T> statement) {
    final stream = _QueryStream(statement, this);
    _activeStreams.add(stream);
    return stream.stream;
  }

  Future<void> handleTableUpdates(String table) async {
    final affectedStreams = _activeStreams.where((stream) => stream.isAffectedByTableChange(table));

    for (var stream in affectedStreams) {
      await stream.fetchAndEmitData();
    }
  }

  void _markAsClosed(_QueryStream stream) {
    _activeStreams.remove(stream);
  }
}

class _QueryStream<T, D> {
  final SelectStatement<T, D> query;
  final StreamQueryStore _store;

  StreamController<List<D>> _controller;

  Stream<List<D>> get stream {
    _controller ??= StreamController.broadcast(
      onListen: _onListen,
      onCancel: _onCancel,
    );

    return _controller.stream;
  }

  _QueryStream(this.query, this._store);

  void _onListen() {
    // first listener added, fetch query
    fetchAndEmitData();
  }

  void _onCancel() {
    // last listener gone, dispose
    _controller.close();
    // todo this removes the stream from the list so that it can be garbage
    // collected. When a stream is never listened to, we have a memory leak as
    // this will never be called. Maybe an Expando would help here?
    _store._markAsClosed(this);
  }

  Future<void> fetchAndEmitData() async {
    if (!_controller.hasListener) return;

    final data = await query.get();

    if (!_controller.isClosed) {
      _controller.add(data);
    }
  }

  bool isAffectedByTableChange(String table) {
    return table == query.table.$tableName;
  }
}
