---
data:
  title: Isolates
  description: Using moor databases on a background isolate
template: layouts/docs/single
---

{% block "blocks/alert" title="New feature" color="primary" %}
The api for background isolates only works with moor version 2.1.0 or newer. Due to
platform limitations, using [moor_ffi]({{ "../Other engines/vm.md" | pageUrl }}) is required when
using a background isolate. Using `moor_flutter` is not supported.
{% endblock %}

## Preparations

To use the isolate api, first enable the appropriate [build option]({{ "builder_options.md" | pageUrl }}) by
creating a file called `build.yaml` in your project root, next to your `pubspec.yaml`. It should have the following
content:
```yaml
targets:
  $default:
    builders:
      moor_generator:
        options:
          generate_connect_constructor: true
```
Next, re-run the build. You can now add another constructor to the generated database class:
```dart
@UseMoor(...)
class TodoDb extends _$TodoDb {
  TodoDb() : super(VmDatabase.memory());

  // this is the new constructor
  TodoDb.connect(DatabaseConnection connection) : super.connect(connection);
}
```

## Using moor in a background isolate

With the database class ready, let's open it on a background isolate
```dart
import 'package:moor/isolate.dart';

// This needs to be a top-level method because it's run on a background isolate
DatabaseConnection _backgroundConnection() {
    // construct the database. You can also wrap the VmDatabase in a "LazyDatabase" if you need to run
    // work before the database opens.
    final database = VmDatabase.memory();
    return DatabaseConnection.fromExecutor(database);
}

void main() async {
    // create a moor executor in a new background isolate. If you want to start the isolate yourself, you
    // can also call MoorIsolate.inCurrent() from the background isolate
    MoorIsolate isolate = await MoorIsolate.spawn(_backgroundConnection);

    // we can now create a database connection that will use the isolate internally. This is NOT what's
    // returned from _backgroundConnection, moor uses an internal proxy class for isolate communication.
    DatabaseConnection connection = await isolate.connect();

    final db = TodoDb.connect(connection);

    // you can now use your database exactly like you regularly would, it transparently uses a 
    // background isolate internally
}
```

If you need to construct the database outside of an `async` context, you can use the new 
`DatabaseConnection.delayed` constructor introduced in moor 3.4. In the example above, you
could synchronously obtain a `TodoDb` by using:

```dart
Future<DatabaseConnection> _connectAsync() async {
  MoorIsolate isolate = await MoorIsolate.spawn(_backgroundConnection);
  return isolate.connect();
}

void main() {
  final db = TodoDb.connect(DatabaseConnection.delayed(_connectAsync()));
}
```

This can be helpful when using moor in DI frameworks, since you have the database available
immediately. Internally, moor will connect when the first query is sent to the database.

### Initialization on the main thread

Platform channels are not available on background isolates, but sometimes you might want to use
a function like `getApplicationDocumentsDirectory` from `path_provider` to construct the database
path. As this function uses a method channel internally, we have to use a trick to initialize the
database.
We're going to start the isolate running the database manually. This allows us to pass additional
data that we calculated on the main thread.

```dart
Future<MoorIsolate> _createMoorIsolate() async {
  // this method is called from the main isolate. Since we can't use
  // getApplicationDocumentsDirectory on a background isolate, we calculate
  // the database path in the foreground isolate and then inform the
  // background isolate about the path.
  final dir = await getApplicationDocumentsDirectory();
  final path = p.join(dir.path, 'db.sqlite');
  final receivePort = ReceivePort();

  await Isolate.spawn(
    _startBackground,
    _IsolateStartRequest(receivePort.sendPort, path),
  );

  // _startBackground will send the MoorIsolate to this ReceivePort
  return (await receivePort.first as MoorIsolate);
}

void _startBackground(_IsolateStartRequest request) {
  // this is the entry point from the background isolate! Let's create
  // the database from the path we received
  final executor = VmDatabase(File(request.targetPath));
  // we're using MoorIsolate.inCurrent here as this method already runs on a
  // background isolate. If we used MoorIsolate.spawn, a third isolate would be
  // started which is not what we want!
  final moorIsolate = MoorIsolate.inCurrent(
    () => DatabaseConnection.fromExecutor(executor),
  );
  // inform the starting isolate about this, so that it can call .connect()
  request.sendMoorIsolate.send(moorIsolate);
}

// used to bundle the SendPort and the target path, since isolate entry point
// functions can only take one parameter.
class _IsolateStartRequest {
  final SendPort sendMoorIsolate;
  final String targetPath;

  _IsolateStartRequest(this.sendMoorIsolate, this.targetPath);
}
```

Here, you can use `DatabaseConnection.delayed(_createMoorIsolate())` to obtain a
`DatabaseConnection` to use in your database.

### Shutting down the isolate

Since multiple `DatabaseConnection`s can exist to a specific `MoorIsolate`, simply calling
`Database.close` won't stop the isolate. You can use the `MoorIsolate.shutdownAll()` for that.
It will disconnect all databases and then close the background isolate, releasing all resources.

## Common operation modes

You can use a `MoorIsolate` across multiple isolates you control and connect from any of them.

__One executor isolate, one foreground isolate__: This is the most common usage mode. You would call
`MoorIsolate.spawn` from the `main` method in your Flutter or Dart app. Similar to the example above,
you could then use moor from the main isolate by connecting with `MoorIsolate.connect` and passing that
connection to a generated database class.

__One executor isolate, multiple client isolates__: The `MoorIsolate` can be sent across multiple
isolates, each of which can use `MoorIsolate.connect` on their own. This is useful to implement
a setup where you have three or more threads:

- The moor executor isolate
- A foreground isolate, probably for Flutter
- Another background isolate, which could be used for networking.

You can then read data from the foreground isolate or start query streams, similar to the example
above. The background isolate would _also_ call `MoorIsolate.connect` and create its own instance
of the generated database class. Writes to one database will be visible to the other isolate and
also update query streams.

To safely send a `MoorIsolate` instance across a `SendPort`, it's recommended to instead send the
underlying `SendPort` used internally by `MoorIsolate`:

```dart
// Don't do this, it doesn't work in all circumstances
void shareMoorIsolate(MoorIsolate isolate, SendPort sendPort) {
  sendPort.send(isolate);
}

// Instead, send the underlying SendPort:
void shareMoorIsolate(MoorIsolate isolate, SendPort sendPort) {
  sendPort.send(isolate.connectPort);
}
```

The receiving end can reconstruct a `MoorIsolate` from a `SendPort` by using the
`MoorIsolate.fromConnectPort` constructor. That `MoorIsolate` behaves exactly like the original
one, but we only had to send a primitive `SendPort` and not a complex Dart object.

## How does this work? Are there any limitations?

All moor features are supported on background isolates and work out of the box. This includes

- Transactions
- Auto-updating queries (even if the table was updated from another isolate)
- Batched updates and inserts
- Custom statements or those generated from an sql api

Please note that, while using a background isolate can reduce lag on the UI thread, the overall
database is going to be slower! There's a overhead involved in sending data between
isolates, and that's exactly what moor has to do internally. If you're not running into dropped
frames because of moor, using a background isolate is probably not necessary for your app.

Internally, moor uses the following model to implement this api:

- __A server isolate__: A single isolate that executes all queries and broadcasts tables updates.
  This is the isolate created by `MoorIsolate.spawn`. It supports any number of clients via an
  rpc-like connection model. Connections are established via `SendPort`s and `ReceivePort`s.
  Internally, the `MoorIsolate` class only contains a reference to a `SendPort` that can be used to 
  establish a connection to the background isolate. This lets users share the `MoorIsolate`
  object across many isolates and connect multiple times. The actual server logic that listens on
  the port is in a private `_MoorServer` class.
- __Client isolates__: Any number of clients in any number of isolates can connect to a `MoorIsolate`.
  The client acts as a moor backend, which means that all queries are built on the client isolate. The
  raw sql string and parameters are then sent to the server isolate, which will enqueue the operation
  and execute it eventually. Implementing the isolate commands at a low level allows users to re-use
  all their code used without the isolate api.
