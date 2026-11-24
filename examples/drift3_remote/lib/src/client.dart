import 'dart:async';

import 'package:drift3_preview/drift.dart';
import 'package:drift3_remote/src/generated/drift.pbgrpc.dart' as gen;
import 'package:fixnum/fixnum.dart';

import 'protocol.dart';

/// A [DriftConnection] using [openConnection] to establish a connection to a
/// drift server over gRPC.
DriftConnection serverConnection(
  DriftDialectFactory dialect,
  FutureOr<gen.DatabaseServiceClient> Function() openConnection,
) {
  return DriftConnection.withImplementation(
    dialect: dialect,
    implementation: (_) async {
      final conn = await openConnection();
      final sessionDescription = await conn.connect(gen.ConnectRequest());

      return OpenedDriftConnection(
        RemoteSession._(conn, sessionDescription),
        RemoteStreamQueryStore._(conn),
      );
    },
  );
}

final class RemoteSession._(
  final gen.DatabaseServiceClient _client,
  final gen.CreatedSession _session,
) implements
    DriftSession,
    DriftSessionWithInternalLocks,
    DriftTransactionSession,
    DriftTransactionParent,
    PersistentSchemaVersion {
  bool _isClosed = false;

  gen.SessionRequest get _request => gen.SessionRequest(session: _session.id);

  @override
  DriftSessionWithInternalLocks? get locks => _session.locks ? this : null;

  @override
  DriftTransactionSession? get transaction =>
      _session.transaction ? this : null;

  @override
  DriftTransactionParent? get transactionParent =>
      _session.transactionParent ? this : null;

  @override
  PersistentSchemaVersion? get persistentSchemaVersion =>
      _session.persistentSchemaVersion ? this : null;

  @override
  Object? get tag => null;

  @override
  bool get isClosed => _isClosed;

  @override
  late final Future<void> closed = _client
      .awaitClosed(_request)
      .then<void>((_) {})
      .whenComplete(() => _isClosed = true);

  @override
  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;
    await _client.close(_request);
  }

  @override
  Future<QueryResult> execute(
    StatementInfo statement, {
    AbortToken? abort,
  }) async {
    final response = await _client.execute(
      gen.ExecuteRequest(
        session: _session.id,
        statement: statementToProto(statement),
      ),
    );
    return resultFromProto(response);
  }

  @override
  Future<List<QueryResult>> executeBatch(
    StatementBatch batch, {
    AbortToken? abort,
  }) async {
    final response = await _client.executeBatch(
      gen.ExecuteBatchRequest(session: _session.id, batch: batchToProto(batch)),
    );
    return response.results.map(resultFromProto).toList();
  }

  @override
  Future<DriftSession> begin(
    TransactionOptions options, {
    AbortToken? abort,
  }) async {
    final created = await _client.begin(
      gen.BeginRequest(
        session: _session.id,
        options: gen.TransactionOptions(
          deferForeignKeys: options.deferForeignKeys,
          readOnly: options.readOnly,
        ),
      ),
    );
    return RemoteSession._(_client, created);
  }

  @override
  Future<DriftSession> exclusive({AbortToken? abort}) async {
    final created = await _client.exclusive(_request);
    return RemoteSession._(_client, created);
  }

  @override
  Future<void> commit() async {
    await _client.commit(_request);
  }

  @override
  Future<void> rollback() async {
    await _client.rollback(_request);
  }

  @override
  Future<int> get schemaVersion async {
    final response = await _client.schemaVersionGet(
      gen.GetSchemaVersion(session: _session.id),
    );
    return response.schemaVersion.toInt();
  }

  @override
  Future<void> writeSchemaVersion(int version) async {
    await _client.schemaVersionSet(
      gen.SetSchemaVersion(schemaVersion: Int64(version), session: _session.id),
    );
  }
}

final class RemoteStreamQueryStore._(final gen.DatabaseServiceClient _client)
    extends StreamQueryStore {
  late final StreamController<Set<TableUpdate>> _updates;
  StreamSubscription<gen.TableUpdates>? _notifications;

  this {
    // Only listen for notifications on the server while streams are active.
    _updates = StreamController.broadcast(
      sync: true,
      onListen: () {
        _notifications = _client
            .tableUpdateNotifications(gen.Empty())
            .listen(
              (event) => _updates.add(tableUpdatesFromProto(event)),
              onError: _updates.addError,
            );
      },
      onCancel: () {
        _notifications?.cancel();
        _notifications = null;
      },
    );
  }

  @override
  Stream<Set<TableUpdate>> updatesForSync(TableUpdateQuery query) {
    return _updates.stream
        .map((e) => e.where(query.matches).toSet())
        .where((e) => e.isNotEmpty);
  }

  @override
  void handleTableUpdates(Set<TableUpdate> updates) {
    if (isShuttingDown || updates.isEmpty) return;

    // Errors are deliberately left unhandled so that they're reported.
    unawaited(_client.dispatchTableUpdates(tableUpdatesToProto(updates)));
  }

  @override
  Future<void> close() async {
    await super.close();
    await _updates.close();
  }
}
