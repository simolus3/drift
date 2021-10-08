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

import 'package:drift/remote.dart';
import 'package:meta/meta.dart';
import 'package:stream_channel/stream_channel.dart';

export 'package:drift/remote.dart' hide DriftServer;

/// Serves a moor database connection over any two-way communication channel.
///
/// Users are responsible for creating the underlying stream channels before
/// passing them to this server via [DriftServer.serve].
/// A single moor server can safely handle multiple clients.
@pragma('moor2drift', 'DriftServer')
typedef MoorServer = DriftServer;
