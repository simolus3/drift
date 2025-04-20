import 'dart:async';

import 'package:drift/src/connections/remote/serialize.dart';
import 'package:stream_channel/stream_channel.dart';

import '../../../connections/remote.dart';
import '../connection.dart';
import 'channel.dart';
import 'protocol.dart';

/// Implements a [DriftServer] making a [DriftSession] available to clients.
final class ServerImplementation implements DriftServer {
  /// The outermost [DriftSession] to expose to clients.
  final DriftDatabaseImplementation connection;

  /// Whether connections are allowed to shut the server down by sending a
  /// [ShutdownServerRequest].
  final bool allowRemoteShutdown;

  /// Whether the [session] should be closed after the server shuts down.
  final bool closeConnectionAfterShutdown;

  bool _isShuttingDown = false;
  final Set<_ActiveConnection> _activeConnections = {};
  final Completer<void> _done = Completer();
  final Completer<DriftSession> _session = Completer();

  final StreamController<NotifyTablesUpdated> _tableUpdateNotifications =
      StreamController();

  /// Creates a server implementation from the underlying [session] and options.
  ServerImplementation({
    required this.connection,
    required this.allowRemoteShutdown,
    required this.closeConnectionAfterShutdown,
  }) {
    done.whenComplete(() {
      _closeRemainingConnections();
      _tableUpdateNotifications.close();
    });
  }

  @override
  Future<void> get done => _done.future;

  Future<DriftSession> _resolveSession() {
    if (!_session.isCompleted) {
      _session.complete(connection.open().then((conn) => conn.$1));
    }
    return _session.future;
  }

  @override
  Stream<NotifyTablesUpdated> get tableUpdateNotifications {
    return _tableUpdateNotifications.stream;
  }

  @override
  Future<void> serve(StreamChannel<Object?> channel, {bool serialize = true}) {
    final comm = DriftChannel(channel.messageChannel(serialize: serialize));

    final connection = _ActiveConnection(comm);
    comm.setRequestHandler((req) => _handleRequest(connection, req));
    _activeConnections.add(connection);
    return comm.closed.then((_) => _activeConnections.remove(connection));
  }

  @override
  Future<void> shutdown() {
    if (!_isShuttingDown) {
      _isShuttingDown = true;
      _done.complete(Future(() async {
        if (closeConnectionAfterShutdown && _session.isCompleted) {
          final session = await _session.future;
          await session.close();
        }
      }));
    }

    return done;
  }

  Future<void> _remoteShutdown() async {
    if (!allowRemoteShutdown) {
      throw StateError('Remote shutdowns are disabled');
    }

    await shutdown();
  }

  void _closeRemainingConnections() {
    for (final channel in _activeConnections) {
      channel.channel.close();
    }
  }

  Future<Response> _handleRequest(
      _ActiveConnection conn, Request request) async {
    DriftSession loadSession(int id) {
      return conn.loadSession(id);
    }

    final id = request.id;
    return switch (request) {
      ClientInitialize() => conn.addSession(id, await _resolveSession()),
      ExecuteRequest(:final sessionId, :final statement) => ExecuteResponse(id,
          result: [await loadSession(sessionId).execute(statement)]),
      ExecuteBatchRequest(:final sessionId, :final batch) => ExecuteResponse(
          sessionId,
          result: await loadSession(sessionId).executeBatch(batch),
        ),
      StartExclusiveRequest() => await conn.startExclusive(request),
      BeginTransactionRequest() => await conn.beginTransaction(request),
      GetSchemaVersion(:final sessionId) => SchemaVersionResponse(
          id, await loadSession(sessionId).root!.schemaVersion),
      WriteSchemaVersion() => await conn.writeSchemaVersion(request),
      CloseSessionRequest(:final sessionId) =>
        await conn.closeSession(id, sessionId),
      ShutdownServerRequest() => _remoteShutdown().then((_) => Response(id)),
    };
  }

  @override
  void dispatchTableUpdateNotification(NotifyTablesUpdated notification) {
    for (final connected in _activeConnections) {
      connected.channel.send(notification);
    }
  }
}

final class _ActiveConnection {
  final DriftChannel channel;
  final Map<int, _ConnectionSession> _activeSessions = {};
  int _nextSessionId = 0;

  _ActiveConnection(this.channel) {
    channel.closed.whenComplete(() {
      for (final session in _activeSessions.values) {
        if (session.ownedByConnection) {
          session.session.close();
        }
      }
    });
  }

  DriftSession loadSession(int id) {
    return (_activeSessions[id] ??
            (throw StateError('Unknown connection id: $id')))
        .session;
  }

  Future<Response> writeSchemaVersion(WriteSchemaVersion version) async {
    await loadSession(version.sessionId)
        .root!
        .writeSchemaVersion(version.schemaVersion);
    return Response(version.id);
  }

  Future<Response> closeSession(int requestId, int session) async {
    await loadSession(session).close();
    return Response(requestId);
  }

  Future<SessionDetails> startExclusive(StartExclusiveRequest request) async {
    final parent = loadSession(request.parentId);
    final started = await parent.locks!.exclusive();
    return addSession(request.id, started, ownedByThisConnection: true);
  }

  Future<SessionDetails> beginTransaction(
      BeginTransactionRequest request) async {
    final parent = loadSession(request.parentId);
    final started = await parent.transactionParent!.begin(request.options);
    return addSession(request.id, started, ownedByThisConnection: true);
  }

  SessionDetails addSession(int requestId, DriftSession session,
      {bool ownedByThisConnection = false}) {
    final id = _nextSessionId++;
    session.closed.then((_) {
      _activeSessions.remove(id);
      if (!channel.isClosed) {
        channel.send(NotifySessionClosed(sessionId: id));
      }
    });
    _activeSessions[id] = _ConnectionSession(session, ownedByThisConnection);

    return SessionDetails(
      requestId,
      sessionId: id,
      isRoot: session.root != null,
      isDriftTransactionParent: session.transactionParent != null,
      isTransaction: session.transaction != null,
      isDriftSessionWithInternalLocks: session.locks != null,
    );
  }
}

final class _ConnectionSession {
  final DriftSession session;
  final bool ownedByConnection;

  _ConnectionSession(this.session, this.ownedByConnection);
}
