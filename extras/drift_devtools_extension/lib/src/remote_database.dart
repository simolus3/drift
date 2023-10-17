import 'dart:async';
import 'dart:convert';

import 'package:devtools_app_shared/service.dart';
import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:drift/drift.dart';
// ignore: invalid_use_of_internal_member, implementation_imports
import 'package:drift/src/runtime/devtools/shared.dart';
// ignore: implementation_imports
import 'package:drift/src/remote/protocol.dart';
import 'package:logging/logging.dart';
import 'list.dart';

/// Utilities to access a drift database via service extensions.
class RemoteDatabase {
  final TrackedDatabase db;
  final DatabaseDescription description;

  int? _remoteSubscriptionId;
  StreamSubscription? _tableNotifications;
  final StreamController<List<TableUpdate>> _tableUpdates =
      StreamController.broadcast();

  Stream<List<TableUpdate>> get tableUpdates => _tableUpdates.stream;

  RemoteDatabase({required this.db, required this.description}) {
    _tableUpdates
      ..onListen = () async {
        try {
          final id = await _newTableSubscription();

          if (_remoteSubscriptionId != null) {
            await _unsubscribeFromTables(_remoteSubscriptionId!);
          }
          _remoteSubscriptionId = id;
          _logger.fine('Received subscription $id for tables.');

          _tableNotifications =
              serviceManager.service!.onExtensionEvent.where((e) {
            return e.extensionKind == 'drift:event' &&
                e.extensionData?.data['subscription'] == id;
          }).listen((event) {
            final payload =
                _protocol.decodePayload(event.extensionData?.data['payload'])
                    as NotifyTablesUpdated;
            _tableUpdates.add(payload.updates);
          });
        } catch (e, s) {
          _tableUpdates
            ..addError(e, s)
            ..close();
        }
      }
      ..onCancel = () {
        final id = _remoteSubscriptionId;
        _remoteSubscriptionId = null;
        if (id != null) {
          _unsubscribeFromTables(id);
        }
      };
  }

  Future<List<Map<String, Object?>>> select(
      String sql, List<Object?> args) async {
    final result = await _executeQuery<SelectResult>(
        ExecuteQuery(StatementMethod.select, sql, args));
    return result.rows;
  }

  Future<void> execute(String sql, List<Object?> args) async {
    await _executeQuery<void>(ExecuteQuery(StatementMethod.custom, sql, args));
  }

  Future<int> _newTableSubscription() async {
    final result = await _driftRequest('subscribe-to-tables');
    return result as int;
  }

  Future<void> _unsubscribeFromTables(int subId) async {
    await _driftRequest('unsubscribe-from-tables',
        payload: {'id': subId.toString()});
    await _tableNotifications?.cancel();
    _tableNotifications = null;
  }

  Future<T> _executeQuery<T>(ExecuteQuery e) async {
    final result = await _driftRequest('execute-query', payload: {
      'query': json.encode(_protocol.encodePayload(e)),
    });

    return _protocol.decodePayload(result) as T;
  }

  Future<Object?> _driftRequest(String method,
      {Map<String, String> payload = const {}}) async {
    final response = await serviceManager.callServiceExtensionOnMainIsolate(
      'ext.drift.database',
      args: {
        'action': method,
        'db': db.id.toString(),
        ...payload,
      },
    );

    return response.json!['r'];
  }

  static Future<RemoteDatabase> resolve(
    TrackedDatabase database,
    EvalOnDartLibrary eval,
    Disposable isAlive,
  ) async {
    final stringVal = await eval.evalInstance(
      'describe(db)',
      isAlive: isAlive,
      scope: {'db': database.database.id!},
    );
    final value = await eval.retrieveFullValueAsString(stringVal);

    final description = DatabaseDescription.fromJson(json.decode(value!));

    return RemoteDatabase(db: database, description: description);
  }

  static final _logger = Logger('RemoteDatabase');
  static const _protocol = DriftProtocol();
}
