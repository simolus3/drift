import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:drift/src/remote/protocol.dart';

import '../query_builder/query_builder.dart';
import 'devtools.dart';

/// A service extension making asynchronous requests on drift databases
/// accessible via the VM service.
///
/// This is used by the drift DevTools extension to run queries and show their
/// results in the DevTools view.
class DriftServiceExtension {
  int _subscriptionId = 0;
  final Map<int, StreamSubscription> _activeSubscriptions = {};

  Future<Object?> _handle(Map<String, String> parameters) async {
    final action = parameters['action']!;
    final databaseId = int.parse(parameters['db']!);
    final tracked = TrackedDatabase.all.firstWhere((e) => e.id == databaseId);

    switch (action) {
      case 'subscribe-to-tables':
        final stream = tracked.database.tableUpdates();
        final id = _subscriptionId++;

        stream.listen((event) {
          postEvent('event', {
            'subscription': id,
            'payload':
                _protocol.encodePayload(NotifyTablesUpdated(event.toList()))
          });
        });

        return id;
      case 'unsubscribe-from-tables':
        _activeSubscriptions.remove(int.parse(parameters['id']!))?.cancel();
        return null;
      case 'execute-query':
        final execute = _protocol
            .decodePayload(json.decode(parameters['query']!)) as ExecuteQuery;
        final variables = [
          for (final variable in execute.args) Variable(variable)
        ];

        final result = await switch (execute.method) {
          StatementMethod.select => tracked.database
              .customSelect(execute.sql, variables: variables)
              .get()
              .then((rows) => SelectResult([for (final row in rows) row.data])),
          StatementMethod.insert =>
            tracked.database.customInsert(execute.sql, variables: variables),
          StatementMethod.deleteOrUpdate =>
            tracked.database.customUpdate(execute.sql, variables: variables),
          StatementMethod.custom => tracked.database
              .customStatement(execute.sql, execute.args)
              .then((_) => 0),
        };

        return _protocol.encodePayload(result);
      default:
        throw UnsupportedError('Method $action');
    }
  }

  static bool _registered = false;

  /// Registers the `ext.drift.database` extension if it has not yet been
  /// registered on this isolate.
  static void registerIfNeeded() {
    if (!_registered) {
      _registered = true;

      final extension = DriftServiceExtension();
      registerExtension('ext.drift.database', (method, parameters) {
        return Future(() => extension._handle(parameters))
            .then((value) => ServiceExtensionResponse.result(json.encode({
                  'r': value,
                })))
            .onError((error, stackTrace) {
          return ServiceExtensionResponse.error(
            ServiceExtensionResponse.extensionErrorMin,
            json.encode(
              {
                'e': error.toString(),
                'trace': stackTrace.toString(),
              },
            ),
          );
        });
      });
    }
  }

  static const _protocol = DriftProtocol();
}
