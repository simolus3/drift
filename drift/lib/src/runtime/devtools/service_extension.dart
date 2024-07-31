import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:drift/drift.dart';
import 'package:drift/src/remote/protocol.dart';
import 'package:drift/src/runtime/executor/transactions.dart';
import 'package:meta/meta.dart';

import '../api/runtime_api.dart';
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

        _activeSubscriptions[id] = stream.listen((event) {
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
      case 'collect-expected-schema':
        final executor = CollectCreateStatements(SqlDialect.sqlite);
        await tracked.database.runConnectionZoned(
            BeforeOpenRunner(tracked.database, executor), () async {
          // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
          final migrator = tracked.database.createMigrator();
          await migrator.createAll();
        });

        return executor.statements;
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

@internal
final class CollectCreateStatements extends QueryExecutor {
  final List<String> statements = [];
  @override
  final SqlDialect dialect;

  CollectCreateStatements(this.dialect);

  @override
  QueryExecutor beginExclusive() {
    return this;
  }

  @override
  TransactionExecutor beginTransaction() {
    throw UnimplementedError();
  }

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) {
    return Future.value(true);
  }

  @override
  Future<void> runBatched(BatchedStatements statements) {
    throw UnimplementedError();
  }

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) {
    statements.add(statement);
    return Future.value();
  }

  @override
  Future<int> runDelete(String statement, List<Object?> args) {
    throw UnimplementedError();
  }

  @override
  Future<int> runInsert(String statement, List<Object?> args) {
    throw UnimplementedError();
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
      String statement, List<Object?> args) {
    throw UnimplementedError();
  }

  @override
  Future<int> runUpdate(String statement, List<Object?> args) {
    throw UnimplementedError();
  }
}
