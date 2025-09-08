import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:drift/drift.dart';

import 'package:meta/meta.dart';

import '../../connections/remote/protocol.dart';
import '../../connections/remote/serialize.dart';
import '../../runtime/database/db_base.dart';
import '../../runtime/database/connection_user.dart';
import '../streams/store_impl.dart';
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
            'payload': _protocol.encode(NotifyTablesUpdated(event.toList()))
          });
        });

        return id;
      case 'unsubscribe-from-tables':
        _activeSubscriptions.remove(int.parse(parameters['id']!))?.cancel();
        return null;
      case 'execute-query':
        final execute = _protocol.decode(json.decode(parameters['query']!))
            as ExecuteRequest;
        final session = await tracked.database.currentSession();
        final response = await session.execute(execute.statement);

        return _protocol.encode(ExecuteResponse(0, result: [response]));
      case 'collect-expected-schema':
        final executor = CollectCreateStatements();

        await tracked.database
            .runConnectionZoned(executor, LocalStreamQueryStore(), () async {
          final migrator = tracked.database.createMigrator();
          await migrator.createAll();
        });

        return executor.statements;
      case 'clear':
        final database = tracked.database;
        await database.exclusively(() async {
          // https://stackoverflow.com/a/65743498/25690041
          await database.customStatement('PRAGMA writable_schema = 1;');
          await database.customStatement('DELETE FROM sqlite_master;');
          await database.customStatement('VACUUM;');
          await database.customStatement('PRAGMA writable_schema = 0;');
          await database.customStatement('PRAGMA integrity_check');

          await database.customStatement('PRAGMA user_version = 0');
          await database.runMigrations();
          await database.customStatement(
              'PRAGMA user_version = ${database.schemaVersion}');

          // Refresh all stream queries
          database.notifyUpdates({
            for (final table
                in database.allSchemaEntities.whereType<GeneratedTable>())
              TableUpdate.onTable(table)
          });
        });
        return true;
      case 'notify-update':
        final database = tracked.database;
        database.notifyUpdates({
          for (final update in json.decode(parameters['updates']!) as List)
            TableUpdate(update['table'] as String),
        });
        return true;
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

  static const _protocol = ProtocolMessageSerializer();
}

@internal
final class CollectCreateStatements implements DriftSession, DriftRootSession {
  final List<String> statements = [];

  final Completer<void> _close = Completer();
  int _schemaVersion = 0;

  CollectCreateStatements();

  @override
  Future<void> close() async {
    _close.complete();
  }

  @override
  Future<void> get closed => _close.future;

  @override
  Future<QueryResult> execute(StatementInfo statement) async {
    if (statement.needsResultSet) {
      throw UnimplementedError();
    }

    statements.add(statement.sql);
    return QueryResult(resultSet: null);
  }

  @override
  Future<List<QueryResult>> executeBatch(StatementBatch batch) {
    return Future.wait(batch.statements.map((e) => execute(e.info)));
  }

  @override
  bool get isClosed => _close.isCompleted;

  @override
  DriftSessionWithInternalLocks? get locks => null;

  @override
  DriftRootSession? get root => this;

  @override
  Object? get tag => null;

  @override
  DriftTransactionSession? get transaction => null;

  @override
  DriftTransactionParent? get transactionParent => null;

  @override
  Future<int> get schemaVersion => Future.value(_schemaVersion);

  @override
  Future<void> writeSchemaVersion(int version) async {
    _schemaVersion = version;
  }
}
