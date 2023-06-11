import 'dart:async';
import 'dart:html';

import 'package:drift/src/runtime/api/runtime_api.dart';
import 'package:drift/src/runtime/executor/stream_queries.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';

/// A [StreamQueryStore] using [web broadcast] APIs
///
/// [web broadcast]: https://developer.mozilla.org/en-US/docs/Web/API/Broadcast_Channel_API
class BroadcastStreamQueryStore extends StreamQueryStore {
  final BroadcastChannel _channel;
  StreamSubscription<MessageEvent>? _messageFromChannel;

  /// Constructs a broadcast query store with the given [identifier].
  ///
  /// All query stores with the same identifier will share stream query updates.
  BroadcastStreamQueryStore(String identifier)
      : _channel = BroadcastChannel('drift_updates_$identifier') {
    _messageFromChannel = _channel.onMessage.listen(_handleMessage);
  }

  void _handleMessage(MessageEvent message) {
    final data = message.data;
    if (data is! List || data.isEmpty) return;

    super.handleTableUpdates({
      for (final entry in data.cast<_SerializedTableUpdate>())
        entry.toTableUpdate,
    });
  }

  @override
  void handleTableUpdates(Set<TableUpdate> updates) {
    super.handleTableUpdates(updates);

    _channel.postMessage([
      for (final update in updates) _SerializedTableUpdate.of(update),
    ]);
  }

  @override
  Future<void> close() async {
    _messageFromChannel?.cancel();
    _channel.close();
    await super.close();
  }

  /// Whether the current JavaScript context supports broadcast channels.
  static bool get supported => hasProperty(globalThis, 'BroadcastChannel');
}

@JS()
@anonymous
@staticInterop
class _SerializedTableUpdate {
  external factory _SerializedTableUpdate({
    required String? kind,
    required String table,
  });

  factory _SerializedTableUpdate.of(TableUpdate update) {
    return _SerializedTableUpdate(kind: update.kind?.name, table: update.table);
  }
}

extension on _SerializedTableUpdate {
  @JS()
  external String? get kind;

  @JS()
  external String get table;

  TableUpdate get toTableUpdate {
    final updateKind = _updateKindByName[kind];

    return TableUpdate(table, kind: updateKind);
  }

  static final _updateKindByName = UpdateKind.values.asNameMap();
}
