import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import '../connection/connection.dart';
import '../connection/result_set.dart';
import '../connection/streams/in_memory_store.dart';
import '../connection/streams/update_rules.dart';
import '../database/connection_user.dart';
import '../database/db_base.dart';
import '../query_builder/schema/table.dart';
import 'platform_unsupported.dart' if (dart.library.io) 'platform_native.dart';

import 'devtools.dart';
import 'shared.dart';

/// A service extension making asynchronous requests on drift databases
/// accessible via the VM service.
///
/// This is used by the drift DevTools extension to run queries and show their
/// results in the DevTools view.
final class DriftServiceExtension {
  int _subscriptionId = 0;
  final Map<int, StreamSubscription<void>> _activeSubscriptions = {};

  Future<Object?> _handle(Map<String, String> parameters) async {
    final action = parameters['action']!;
    final databaseId = int.parse(parameters['db']!);
    final tracked = TrackedDatabase.all.firstWhere((e) => e.id == databaseId);

    switch (action) {
      case 'get-supported-features':
        return {'isExportSupported': isExportSupported};
      case 'download':
        final exported = await exportDatabase(tracked.database);

        return {
          'database': tracked.database.runtimeType.toString(),
          'data': base64.encode(exported),
        };
      case 'subscribe-to-tables':
        final stream = tracked.database.tableUpdates();
        final id = _subscriptionId++;

        _activeSubscriptions[id] = stream.listen((event) {
          postEvent('event', {
            'subscription': id,
            'payload': [
              for (final update in event)
                {'table': update.table, 'kind': update.kind?.name},
            ],
          });
        });

        return id;
      case 'unsubscribe-from-tables':
        _activeSubscriptions.remove(int.parse(parameters['id']!))?.cancel();
        return null;
      case 'execute-query':
        final sql = parameters['sql']!;
        final sqlParameters = json.decode(parameters['parameters']!) as List;
        final needResults = parameters['includeResults'] == 'true';

        final session = await tracked.database.currentSession();
        final result = await session.execute(
          StatementInfo(
            sql,
            variables: [
              for (final param in sqlParameters)
                decodeSqlValue(tracked.database, param),
            ],
            needsResultSet: needResults,
          ),
        );

        if (result.resultSet case final resultSet?) {
          return {
            'columnNames': resultSet.columnNames,
            'rows': [
              for (final row in resultSet)
                for (final value in row) encodeSqlValue(value),
            ],
          };
        } else {
          return null;
        }
      case 'collect-expected-schema':
        final collector = CollectCreateStatements();
        await tracked.database.runConnectionZoned(
          collector,
          InMemoryStreamQueryStore(),
          () async {
            // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
            final migrator = tracked.database.createMigrator();
            await migrator.createAll();
          },
        );

        return collector.statements;
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
            'PRAGMA user_version = ${database.schemaVersion}',
          );

          // Refresh all stream queries
          database.notifyUpdates({
            for (final entity in database.schema)
              if (entity is GeneratedTable) TableUpdate.onTable(entity),
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
            .then(
              (value) =>
                  ServiceExtensionResponse.result(json.encode({'r': value})),
            )
            .onError((error, stackTrace) {
              return ServiceExtensionResponse.error(
                ServiceExtensionResponse.extensionErrorMin,
                json.encode({
                  'e': error.toString(),
                  'trace': stackTrace.toString(),
                }),
              );
            });
      });
    }
  }
}

/// Noop [DriftSession] implementation collecting executed statements.
final class CollectCreateStatements implements DriftSession {
  /// All SQL statements executed on this session.
  final List<String> statements = [];

  final _closed = Completer<void>();

  @override
  Future<void> close() {
    if (!_closed.isCompleted) _closed.complete();
    return closed;
  }

  @override
  Future<void> get closed => _closed.future;

  @override
  bool get isClosed => _closed.isCompleted;

  @override
  Future<QueryResult> execute(StatementInfo statement) async {
    statements.add(statement.sql);
    return QueryResult(resultSet: null);
  }

  @override
  Future<List<QueryResult>> executeBatch(StatementBatch batch) {
    throw UnimplementedError();
  }

  @override
  DriftSessionWithInternalLocks? get locks => null;

  @override
  PersistentSchemaVersion? get persistentSchemaVersion => null;

  @override
  Object? get tag => null;

  @override
  DriftTransactionSession? get transaction => null;

  @override
  DriftTransactionParent? get transactionParent => throw UnimplementedError();
}
