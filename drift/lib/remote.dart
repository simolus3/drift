/// Library support for accessing remote databases.
///
/// This library provides support for database servers and remote clients. It
/// makes few assumptions over the underlying two-way communication channel,
/// except that it must adhere to the [StreamChannel] guarantees.
///
/// This allows you to use a drift database (including stream queries) over a
/// remote connection as it were a local database. For instance, this api could
/// be used for
///
///  - accessing databases on a remote isolate: The `package:drift/isolate.dart`
///    library is implemented on top of this library.
///  - running databases in web workers
///  - synchronizing stream queries and data across multiple tabs with shared
///    web workers
///  - accessing databases over TCP or WebSockets.
///
/// Drift uses an internal protocol to serialize database requests over stream
/// channels. To make the implementation of channels easier, drift guarantees
/// that nothing but the following messages will be sent:
///
///  - primitive values (`null`, [int], [bool], [double], [String])
///  - lists
///
/// Lists are allowed to nest, but drift will never send messages with cyclic
/// references. Implementations are not required to reserve the type argument
/// of lists when serializing them.
/// However, note that drift might encode a `List<int>` as `Uint8List`. For
/// performance reasons, channel implementations should preserve this.
///
/// Drift assumes full control over the [StreamChannel]s it manages. For this
/// reason, do not send your own messages over them or close them prematurely.
/// If you need further channels over the same underlying connection, consider a
/// [MultiChannel] instead.
///
/// The public apis of this libraries are stable. The present [experimental]
/// annotation refers to the underlying protocol implementation.
/// As long as this library is marked as experimental, the communication
/// protocol can change in every version. For this reason, please make sure that
/// all channel participants are using the exact same drift version.
/// For local communication across isolates or web workers, this is usually not
/// an issue.
///
/// For an example of a channel implementation, you could study the
/// implementation of the `package:drift/isolate.dart` library, which uses this
/// library to implement its apis.
/// The [web](https://drift.simonbinder.eu/web/) documentation on the website
/// contains another implementation based on web workers that might be of
/// interest.
@experimental
library drift.remote;

import 'package:meta/meta.dart';
import 'package:stream_channel/stream_channel.dart';

import 'drift.dart';
import 'remote.dart' as global;
import 'src/remote/client_impl.dart';
import 'src/remote/communication.dart';
import 'src/remote/protocol.dart';
import 'src/remote/server_impl.dart';

export 'src/remote/communication.dart' show DriftRemoteException;

/// Serves a drift database connection over any two-way communication channel.
///
/// Users are responsible for creating the underlying stream channels before
/// passing them to this server via [serve].
/// A single drift server can safely handle multiple clients.
@sealed
abstract class DriftServer {
  /// Creates a drift server proxying incoming requests to the underlying
  /// [connection].
  ///
  /// If [allowRemoteShutdown] is set to `true` (it defaults to `false`),
  /// clients can use [shutdown] to stop this server remotely.
  /// If [closeConnectionAfterShutdown] is set to `true` (the default), shutting
  /// down the server will also close the [connection].
  factory DriftServer(DatabaseConnection connection,
      {bool allowRemoteShutdown = false,
      bool closeConnectionAfterShutdown = true}) {
    return ServerImplementation(
        connection, allowRemoteShutdown, closeConnectionAfterShutdown);
  }

  /// A stream of table update notifications sent from clients to this server.
  ///
  /// This only includes notifications sent from clients, not those dispatched
  /// via [dispatchTableUpdateNotification] or by sending updates to the stream
  /// query store of the underlying connection.
  Stream<NotifyTablesUpdated> get tableUpdateNotifications;

  /// A future that completes when this server has been shut down.
  ///
  /// This future completes after [shutdown] is called directly on this
  /// instance, or if a remote client uses [global.shutdown] on a connection
  /// handled by this server.
  Future<void> get done;

  /// Starts processing requests from the [channel].
  ///
  /// The [channel] uses a drift-internal protocol to serialize database
  /// requests. Drift assumes full control over the [channel]. Manually sending
  /// messages over it, or closing it prematurely, can disrupt the server.
  ///
  /// If [serialize] is true, drift will only send [bool], [int], [double],
  /// [Uint8List], [String] or [List]'s thereof over the channel. Otherwise,
  /// the message may be any Dart object.
  ///
  /// After calling [serve], you can obtain a [DatabaseConnection] on the other
  /// end of the [channel] by calling [connectToRemoteAndInitialize].
  ///
  /// __Warning__: As long as this library is marked experimental, the protocol
  /// might change with every drift version. For this reason, make sure that
  /// your server and clients are using the exact same version of the drift
  /// package to avoid conflicts.
  void serve(StreamChannel<Object?> channel, {bool serialize = true});

  /// Shuts this server down.
  ///
  /// The server will continue to handle ongoing requests, but enqueued or new
  /// requests will be rejected.
  ///
  /// This future returns after all client connections have been closed.
  Future<void> shutdown();

  /// Forwards the [notification] for updated tables to all clients.
  void dispatchTableUpdateNotification(NotifyTablesUpdated notification);
}

/// Connects to a remote server over a two-way communication channel.
///
/// The other end of the [channel] must be attached to a drift server with
/// [DriftServer.serve] for this setup to work.
///
/// If it is known that only a single client will connect to this database
/// server, [singleClientMode] can be enabled.
/// When enabled, [shutdown] is implicitly called when the database connection
/// is closed. This may make it easier to dispose the remote isolate or server.
/// Also, update notifications for table updates don't have to be sent which
/// reduces load on the connection.
///
/// If [serialize] is true, drift will only send [bool], [int], [double],
/// [Uint8List], [String] or [List]'s thereof over the channel. Otherwise,
/// the message may be any Dart object.
/// The value of [serialize] for [remote] must be the same value passed to
/// [DriftServer.serve].
///
/// The optional [debugLog] can be enabled to print incoming and outgoing
/// messages.
///
/// __NOTE__: This synchronous method has a flaw, as its [QueryExecutor.dialect]
/// is always going to be [SqlDialect.sqlite]. While this not a problem in most
/// scenarios where that is the actual database, it makes it harder to use with
/// other database clients. The [connectToRemoteAndInitialize] method does not
/// have this issue.
///
/// Due to this problem, it is recommended to avoid [remote] altogether. If you
/// know the dialect beforehand, you can wrap [connectToRemoteAndInitialize] in
/// a [DatabaseConnection.delayed] to get a connection sychronously.
@Deprecated('Use the asynchronous `connectToRemoteAndInitialize` instead')
DatabaseConnection remote(
  StreamChannel<Object?> channel, {
  bool debugLog = false,
  bool serialize = true,
  bool singleClientMode = false,
}) {
  final client = DriftClient(channel, debugLog, serialize, singleClientMode);
  return client.connection;
}

/// Connects to a remote server over a two-way communication channel.
///
/// The other end of the [channel] must be attached to a drift server with
/// [DriftServer.serve] for this setup to work.
///
/// If it is known that only a single client will connect to this database
/// server, [singleClientMode] can be enabled.
/// When enabled, [shutdown] is implicitly called when the database connection
/// is closed. This may make it easier to dispose the remote isolate or server.
/// Also, update notifications for table updates don't have to be sent which
/// reduces load on the connection.
///
/// If [serialize] is true, drift will only send [bool], [int], [double],
/// [Uint8List], [String] or [List]'s thereof over the channel. Otherwise,
/// the message may be any Dart object.
/// The value of [serialize] for [connectToRemoteAndInitialize] must be the same
/// value passed to [DriftServer.serve].
///
/// The optional [debugLog] can be enabled to print incoming and outgoing
/// messages.
Future<DatabaseConnection> connectToRemoteAndInitialize(
  StreamChannel<Object?> channel, {
  bool debugLog = false,
  bool serialize = true,
  bool singleClientMode = false,
}) async {
  final client = DriftClient(channel, debugLog, serialize, singleClientMode);
  await client.serverInfo;
  return client.connection;
}

/// Sends a shutdown request over a channel.
///
/// On the remote side, the corresponding channel must have been passed to
/// [DriftServer.serve] for this setup to work.
/// Also, the [DriftServer] must have been configured to allow remote-shutdowns.
Future<void> shutdown(StreamChannel<Object?> channel, {bool serialize = true}) {
  final comm = DriftCommunication(channel, serialize: serialize);
  return comm
      .request<void>(NoArgsRequest.terminateAll)
      // Sending a terminate request will stop the server, so we won't get a
      // response. This is expected and not an error we should throw.
      .onError<ConnectionClosedException>((error, stackTrace) => null)
      .whenComplete(comm.close);
}
