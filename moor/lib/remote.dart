/// Library support for accessing remote databases.
///
/// This library provides support for database servers and remote clients. It
/// makes few assumptions over the underlying two-way communication channel,
/// except that it must adhere to the [StreamChannel] guarantees.
///
/// This allows you to use a moor database (including stream queries) over a
/// remote connection as it were a local database. For instance, this api could
/// be used for
///
///  - accessing databases on a remote isolate: The `package:moor/isolate.dart`
///    library is implemented on top of this library.
///  - running databases in web workers
///  - synchronizing stream queries and data across multiple tabs with shared
///    web workers
///  - accessing databases over TCP or WebSockets.
///
/// Moor uses an internal protocol to serialize database requests over stream
/// channels. To make the implementation of channels easier, moor guarantees
/// that nothing but the following messages will be sent:
///
///  - primitive values (`null`, [int], [bool], [double], [String])
///  - lists
///
/// Lists are allowed to nest, but moor will never send messages with cyclic
/// references. Implementations are not required to reserve the type argument
/// of lists when serializing them.
/// However, note that moor might encode a `List<int>` as `Uint8List`. For
/// performance reasons, channel implementations should preserve this.
///
/// Moor assumes full control over the [StreamChannel]s it manages. For this
/// reason, do not send your own messages over them or close them prematurely.
/// If you need further channels over the same underlying connection, consider a
/// [MultiChannel] instead.
///
/// The public apis of this libraries are stable. The present [experimental]
/// annotation refers to the underlying protocol implementation.
/// As long as this library is marked as experimental, the communication
/// protocol can change in every version. For this reason, please make sure that
/// all channel participants are using the exact same moor version.
/// For local communication across isolates or web workers, this is usually not
/// an issue.
///
/// For an example of a channel implementation, you could study the
/// implementation of the `package:moor/isolate.dart` library, which uses this
/// library to implement its apis.
/// The [web](https://moor.simonbinder.eu/web/) documentation on the website
/// contains another implementation based on web workers that might be of
/// interest.
@experimental
library remote;

import 'package:meta/meta.dart';
import 'package:stream_channel/stream_channel.dart';

import 'moor.dart';
import 'remote.dart' as self;

import 'src/runtime/remote/client_impl.dart';
import 'src/runtime/remote/communication.dart';
import 'src/runtime/remote/protocol.dart';
import 'src/runtime/remote/server_impl.dart';

/// Serves a moor database connection over any two-way communication channel.
///
/// Users are responsible for creating the underlying stream channels before
/// passing them to this server via [serve].
/// A single moor server can safely handle multiple clients.
@sealed
abstract class MoorServer {
  /// Creates a moor server proxying incoming requests to the underlying
  /// [connection].
  ///
  /// If [allowRemoteShutdown] is set to `true` (it defaults to `false`),
  /// clients can use [shutdown] to stop this server remotely.
  factory MoorServer(DatabaseConnection connection,
      {bool allowRemoteShutdown = false}) {
    return ServerImplementation(connection, allowRemoteShutdown);
  }

  /// A future that completes when this server has been shut down.
  ///
  /// This future completes after [shutdown] is called directly on this
  /// instance, or if a remote client uses [self.shutdown] on a connection
  /// handled by this server.
  Future<void> get done;

  /// Starts processing requests from the [channel].
  ///
  /// The [channel] uses a moor-internal protocol to serialize database
  /// requests. Moor assumes full control over the [channel]. Manually sending
  /// messages over it, or closing it prematurely, can disrupt the server.
  ///
  /// __Warning__: As long as this library is marked experimental, the protocol
  /// might change with every moor version. For this reason, make sure that your
  /// server and clients are using the exact same version of the moor package to
  /// avoid conflicts.
  void serve(StreamChannel<Object?> channel);

  /// Shuts this server down.
  ///
  /// The server will continue to handle ongoing requests, but enqueued or new
  /// requests will be rejected.
  ///
  /// This future returns after all client connections have been closed.
  Future<void> shutdown();
}

/// Connects to a remote server over a two-way communication channel.
///
/// On the remote side, the corresponding [channel] must have been passed to
/// [MoorServer.serve] for this setup to work.
///
/// The optional [debugLog] can be enabled to print incoming and outgoing
/// messages.
DatabaseConnection remote(StreamChannel<Object?> channel,
    {bool debugLog = false}) {
  final client = MoorClient(channel, debugLog);
  return client.connection;
}

/// Sends a shutdown request over a channel.
///
/// On the remote side, the corresponding channel must have been passed to
/// [MoorServer.serve] for this setup to work.
/// Also, the [MoorServer] must have been configured to allow remote-shutdowns.
Future<void> shutdown(StreamChannel<Object?> channel) {
  final comm = MoorCommunication(channel);
  return comm.request(NoArgsRequest.terminateAll);
}
