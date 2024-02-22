@JS()
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:drift/src/runtime/api/runtime_api.dart';
import 'package:drift/src/runtime/executor/stream_queries.dart';
import 'package:web/web.dart' as web;

@JS('Array')
extension type _ArrayWrapper._(JSArray _) implements JSObject {
  external static JSBoolean isArray(JSAny? value);
}

/// A [StreamQueryStore] using [web broadcast] APIs
///
/// [web broadcast]: https://developer.mozilla.org/en-US/docs/Web/API/Broadcast_Channel_API
class BroadcastStreamQueryStore extends StreamQueryStore {
  final web.BroadcastChannel _channel;
  StreamSubscription<web.MessageEvent>? _messageFromChannel;

  /// Constructs a broadcast query store with the given [identifier].
  ///
  /// All query stores with the same identifier will share stream query updates.
  BroadcastStreamQueryStore(String identifier)
      : _channel = web.BroadcastChannel('drift_updates_$identifier') {
    _messageFromChannel = web.EventStreamProviders.messageEvent
        .forTarget(_channel)
        .listen(_handleMessage);
  }

  void _handleMessage(web.MessageEvent message) {
    final data = message.data;
    if (!_ArrayWrapper.isArray(data).toDart) {
      return;
    }

    final asList = (data as JSArray).toDart;
    if (asList.isEmpty) return;

    super.handleTableUpdates({
      for (final entry in asList.cast<_SerializedTableUpdate>())
        entry.toTableUpdate,
    });
  }

  @override
  void handleTableUpdates(Set<TableUpdate> updates) {
    super.handleTableUpdates(updates);

    _channel.postMessage([
      for (final update in updates) _SerializedTableUpdate.of(update),
    ].toJS);
  }

  @override
  Future<void> close() async {
    _messageFromChannel?.cancel();
    _channel.close();
    await super.close();
  }

  /// Whether the current JavaScript context supports broadcast channels.
  static bool get supported => globalContext.has('BroadcastChannel');
}

@JS()
@anonymous
extension type _SerializedTableUpdate._(JSObject _) implements JSObject {
  external factory _SerializedTableUpdate({
    required JSString? kind,
    required JSString table,
  });

  factory _SerializedTableUpdate.of(TableUpdate update) {
    return _SerializedTableUpdate(
      kind: update.kind?.name.toJS,
      table: update.table.toJS,
    );
  }

  external JSString? get kind;
  external JSString get table;

  TableUpdate get toTableUpdate {
    final updateKind = _updateKindByName[kind?.toDart];

    return TableUpdate(table.toDart, kind: updateKind);
  }

  static final _updateKindByName = UpdateKind.values.asNameMap();
}
