import 'dart:async';

import 'package:drift3_preview/drift.dart';
import 'package:drift3_remote/src/generated/drift.pbgrpc.dart' as gen;
import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import 'protocol.dart';

final class DriftDatabaseServer(final DriftSession _session)
    extends gen.DatabaseServiceBase {
  final StreamQueryStore _streamQueries = InMemoryStreamQueryStore();

  final Map<int, _HostedSession> _sessionsById = {};
  int _nextSessionId = 1;

  /// Registers a session so that clients can refer to it by its id.
  ///
  /// If [owned] is true, closing the session through the `Close` RPC closes
  /// the underlying [DriftSession]. Otherwise (for the root session shared by
  /// all clients), closing it only removes the registration.
  gen.CreatedSession _register(DriftSession session, {required bool owned}) {
    final id = _nextSessionId++;
    final hosted = _sessionsById[id] = _HostedSession(session, owned: owned);

    session.closed.whenComplete(() => _unregister(id, hosted));

    return gen.CreatedSession(
      id: id,
      persistentSchemaVersion: session.persistentSchemaVersion != null,
      transaction: session.transaction != null,
      transactionParent: session.transactionParent != null,
      locks: session.locks != null,
    );
  }

  void _unregister(int id, _HostedSession session) {
    if (_sessionsById[id] == session) {
      _sessionsById.remove(id);
    }
    if (!session.unregistered.isCompleted) {
      session.unregistered.complete();
    }
  }

  _HostedSession _lookup(int id) {
    return _sessionsById[id] ??
        (throw GrpcError.notFound('Session $id does not exist or is closed'));
  }

  static T _require<T extends Object>(T? capability, String name) {
    return capability ??
        (throw GrpcError.unimplemented('Session does not support $name'));
  }

  @override
  Future<gen.CreatedSession> connect(
    ServiceCall call,
    gen.ConnectRequest request,
  ) async {
    if (_session.isClosed) {
      throw GrpcError.unavailable('The database has been closed');
    }

    return _register(_session, owned: false);
  }

  @override
  Future<gen.Empty> close(ServiceCall call, gen.SessionRequest request) async {
    final hosted = _sessionsById[request.session];
    if (hosted == null) {
      // Already closed, closing again is a no-op.
      return gen.Empty();
    }

    _unregister(request.session, hosted);
    if (hosted.owned) {
      await hosted.session.close();
    }
    return gen.Empty();
  }

  @override
  Future<gen.Empty> awaitClosed(
    ServiceCall call,
    gen.SessionRequest request,
  ) async {
    final hosted = _sessionsById[request.session];
    if (hosted != null) {
      await hosted.unregistered.future;
    }

    return gen.Empty();
  }

  @override
  Future<gen.QueryResult> execute(
    ServiceCall call,
    gen.ExecuteRequest request,
  ) async {
    final session = _lookup(request.session).session;
    final result = await session.execute(statementFromProto(request.statement));
    return resultToProto(result);
  }

  @override
  Future<gen.BatchResult> executeBatch(
    ServiceCall call,
    gen.ExecuteBatchRequest request,
  ) async {
    final session = _lookup(request.session).session;
    final results = await session.executeBatch(batchFromProto(request.batch));
    return gen.BatchResult(results: results.map(resultToProto));
  }

  @override
  Future<gen.GetSchemaVersionResult> schemaVersionGet(
    ServiceCall call,
    gen.GetSchemaVersion request,
  ) async {
    final session = _lookup(request.session).session;
    final version = _require(
      session.persistentSchemaVersion,
      'persistent schema versions',
    );

    return gen.GetSchemaVersionResult(
      schemaVersion: Int64(await version.schemaVersion),
    );
  }

  @override
  Future<gen.Empty> schemaVersionSet(
    ServiceCall call,
    gen.SetSchemaVersion request,
  ) async {
    final session = _lookup(request.session).session;
    final version = _require(
      session.persistentSchemaVersion,
      'persistent schema versions',
    );

    await version.writeSchemaVersion(request.schemaVersion.toInt());
    return gen.Empty();
  }

  @override
  Future<gen.CreatedSession> begin(
    ServiceCall call,
    gen.BeginRequest request,
  ) async {
    final session = _lookup(request.session).session;
    final parent = _require(session.transactionParent, 'transactions');

    final transaction = await parent.begin(
      TransactionOptions(
        deferForeignKeys: request.options.hasDeferForeignKeys()
            ? request.options.deferForeignKeys
            : null,
        readOnly: request.options.readOnly,
      ),
    );
    return _register(transaction, owned: true);
  }

  @override
  Future<gen.CreatedSession> exclusive(
    ServiceCall call,
    gen.SessionRequest request,
  ) async {
    final session = _lookup(request.session).session;
    final locks = _require(session.locks, 'exclusive locks');

    return _register(await locks.exclusive(), owned: true);
  }

  @override
  Future<gen.Empty> commit(ServiceCall call, gen.SessionRequest request) async {
    final session = _lookup(request.session).session;
    await _require(session.transaction, 'transactions').commit();
    return gen.Empty();
  }

  @override
  Future<gen.Empty> rollback(
    ServiceCall call,
    gen.SessionRequest request,
  ) async {
    final session = _lookup(request.session).session;
    await _require(session.transaction, 'transactions').rollback();
    return gen.Empty();
  }

  @override
  Future<gen.Empty> dispatchTableUpdates(
    ServiceCall call,
    gen.TableUpdates request,
  ) async {
    _streamQueries.handleTableUpdates(tableUpdatesFromProto(request));
    return gen.Empty();
  }

  @override
  Stream<gen.TableUpdates> tableUpdateNotifications(
    ServiceCall call,
    gen.Empty request,
  ) {
    return _streamQueries
        .updatesForSync(const TableUpdateQuery.any())
        .map(tableUpdatesToProto);
  }
}

final class _HostedSession {
  final DriftSession session;
  final bool owned;

  /// Completes when the session has been closed or when the client released
  /// it with the `Close` RPC.
  final Completer<void> unregistered = Completer();

  _HostedSession(this.session, {required this.owned});
}
