---
data:
  title: Isolates
  description: Using drift databases on a background isolate
template: layouts/docs/single
---

## Preparations

To use the isolate api, first enable the appropriate [build option]({{ "builder_options.md" | pageUrl }}) by
creating a file called `build.yaml` in your project root, next to your `pubspec.yaml`. It should have the following
content:
```yaml
targets:
  $default:
    builders:
      drift_dev:
        options:
          generate_connect_constructor: true
```

Next, re-run the build. You can now add another constructor to the generated database class:

```dart
@DriftDatabase(...)
class TodoDb extends _$TodoDb {
  // Your existing constructor, whatever it may be...
  TodoDb() : super(NativeDatabase.memory());

  // this is the new constructor
  TodoDb.connect(DatabaseConnection connection) : super.connect(connection);
}
```

## Using drift in a background isolate {#using-moor-in-a-background-isolate}

With the database class ready, let's open it on a background isolate
```dart
import 'package:drift/isolate.dart';

// This needs to be a top-level method because it's run on a background isolate
DatabaseConnection _backgroundConnection() {
    // Construct the database to use. This example uses a non-persistent in-memory database each
    // time. You can use your existing NativeDatabase with a file as well, or a `LazyDatabase` if you
    // need to construct it asynchronously.
    // When using a Flutter plugin like `path_provider` to determine the path, also see the
    // "Initialization on the main thread" section below!
    final database = NativeDatabase.memory();
    return DatabaseConnection.fromExecutor(database);
}

void main() async {
    // create a drift executor in a new background isolate. If you want to start the isolate yourself, you
    // can also call DriftIsolate.inCurrent() from the background isolate
    DriftIsolate isolate = await DriftIsolate.spawn(_backgroundConnection);

    // we can now create a database connection that will use the isolate internally. This is NOT what's
    // returned from _backgroundConnection, drift uses an internal proxy class for isolate communication.
    DatabaseConnection connection = await isolate.connect();

    final db = TodoDb.connect(connection);

    // you can now use your database exactly like you regularly would, it transparently uses a 
    // background isolate internally
}
```

If you need to construct the database outside of an `async` context, you can use the 
`DatabaseConnection.delayed` constructor. In the example above, you
could synchronously obtain a `TodoDb` by using:

```dart
Future<DatabaseConnection> _connectAsync() async {
  DriftIsolate isolate = await DriftIsolate.spawn(_backgroundConnection);
  return isolate.connect();
}

void main() {
  final db = TodoDb.connect(DatabaseConnection.delayed(_connectAsync()));
}
```

This can be helpful when using drift in DI frameworks, since you have the database available
immediately. Internally, drift will connect when the first query is sent to the database.

### Initialization on the main thread

Platform channels are not available on background isolates, but sometimes you might want to use
a function like `getApplicationDocumentsDirectory` from `path_provider` to construct the database
path. As this function uses a method channel internally, we have to use a trick to initialize the
database.
We're going to start the isolate running the database manually. This allows us to pass additional
data that we calculated on the main thread.

```dart
Future<DriftIsolate> _createDriftIsolate() async {
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

  // _startBackground will send the DriftIsolate to this ReceivePort
  return await receivePort.first as DriftIsolate;
}

void _startBackground(_IsolateStartRequest request) {
  // this is the entry point from the background isolate! Let's create
  // the database from the path we received
  final executor = NativeDatabase(File(request.targetPath));
  // we're using DriftIsolate.inCurrent here as this method already runs on a
  // background isolate. If we used DriftIsolate.spawn, a third isolate would be
  // started which is not what we want!
  final driftIsolate = DriftIsolate.inCurrent(
    () => DatabaseConnection.fromExecutor(executor),
  );
  // inform the starting isolate about this, so that it can call .connect()
  request.sendDriftIsolate.send(driftIsolate);
}

// used to bundle the SendPort and the target path, since isolate entry point
// functions can only take one parameter.
class _IsolateStartRequest {
  final SendPort sendDriftIsolate;
  final String targetPath;

  _IsolateStartRequest(this.sendDriftIsolate, this.targetPath);
}
```

Once again, you can use a `DatabaseConnection.delayed()` to obtain a database
connection for your database class:

```dart
DatabaseConnection _createDriftIsolateAndConnect() {
  return DatabaseConnection.delayed(() async {
    final isolate = await _createDriftIsolate();
    return await isolate.connect();
  }());
}
```

{% block "blocks/alert" title="Initializations and background isolates" color="warning" %}
As the name implies, Dart isolates don't share memory. This means that global variables
and values accessible in one isolate may not be visible in a background isolate.

For instance, if you're using `open.overrideFor` from `package:sqlite3`, you need to do that
on the isolate where you're actually opening the database!
With a background isolate as shown here, the right place to call `open.overrideFor` is in the
`_startBackground` function, before you're using `DriftIsolate.inCurrent`.
Other global fields that you might be relying on when constructing the database (service
locators like `get_it` come to mind) may also need to be initialized separately on the background
isolate.
{% endblock %}

### Shutting down the isolate

Since multiple `DatabaseConnection`s can exist to a specific `DriftIsolate`, simply calling
`Database.close` won't stop the isolate. You can use the `DriftIsolate.shutdownAll()` for that.
It will disconnect all databases and then close the background isolate, releasing all resources.

## Common operation modes

You can use a `DriftIsolate` across multiple isolates you control and connect from any of them.

__One executor isolate, one foreground isolate__: This is the most common usage mode. You would call
`DriftIsolate.spawn` from the `main` method in your Flutter or Dart app. Similar to the example above,
you could then use drift from the main isolate by connecting with `DriftIsolate.connect` and passing that
connection to a generated database class.

__One executor isolate, multiple client isolates__: The `DriftIsolate` can be sent across multiple
isolates, each of which can use `DriftIsolate.connect` on their own. This is useful to implement
a setup where you have three or more threads:

- The drift executor isolate
- A foreground isolate, probably for Flutter
- Another background isolate, which could be used for networking.

You can then read data from the foreground isolate or start query streams, similar to the example
above. The background isolate would _also_ call `DriftIsolate.connect` and create its own instance
of the generated database class. Writes to one database will be visible to the other isolate and
also update query streams.

To safely send a `DriftIsolate` instance across a `SendPort`, it's recommended to instead send the
underlying `SendPort` used internally by `DriftIsolate`:

```dart
// Don't do this, it doesn't work in all circumstances
void shareDriftIsolate(DriftIsolate isolate, SendPort sendPort) {
  sendPort.send(isolate);
}

// Instead, send the underlying SendPort:
void shareDriftIsolate(DriftIsolate isolate, SendPort sendPort) {
  sendPort.send(isolate.connectPort);
}
```

The receiving end can reconstruct a `DriftIsolate` from a `SendPort` by using the
`DriftIsolate.fromConnectPort` constructor. That `DriftIsolate` behaves exactly like the original
one, but we only had to send a primitive `SendPort` and not a complex Dart object.

## How does this work? Are there any limitations?

All drift features are supported on background isolates and work out of the box. This includes

- Transactions
- Auto-updating queries (even if the table was updated from another isolate)
- Batched updates and inserts
- Custom statements or those generated from an sql api

Please note that, while using a background isolate can reduce lag on the UI thread, the overall
database is going to be slower! There's a overhead involved in sending data between
isolates, and that's exactly what drift has to do internally. If you're not running into dropped
frames because of drift, using a background isolate is probably not necessary for your app.

Internally, drift uses the following model to implement this api:

- __A server isolate__: A single isolate that executes all queries and broadcasts tables updates.
  This is the isolate created by `DriftIsolate.spawn`. It supports any number of clients via an
  rpc-like connection model. Connections are established via `SendPort`s and `ReceivePort`s.
  Internally, the `DriftIsolate` class only contains a reference to a `SendPort` that can be used to 
  establish a connection to the background isolate. This lets users share the `DriftIsolate`
  object across many isolates and connect multiple times. The actual server logic that listens on
  the port is in a private `RunningDriftServer` class.
- __Client isolates__: Any number of clients in any number of isolates can connect to a `DriftIsolate`.
  The client acts as a drift backend, which means that all queries are built on the client isolate. The
  raw sql string and parameters are then sent to the server isolate, which will enqueue the operation
  and execute it eventually. Implementing the isolate commands at a low level allows users to re-use
  all their code used without the isolate api.

## Independent isolates

All setups mentioned here assume that there will be one main isolate responsible for spawning a
`DriftIsolate` that it (and other isolates) can then connect to.

In Flutter apps, this model may not always fit your use case.
For instance, your app may use background tasks or receive FCM notifications while closed.
These tasks will run in a background `FlutterEngine` managed by native platform code, so there's
no clear communication scheme between isolates.
Still, you may want to share a live drift database between your UI engine and potential background engines,
even without them directly knowing about each other.

An [IsolateNameServer](https://api.flutter.dev/flutter/dart-ui/IsolateNameServer-class.html) from `dart:ui` can
be used to transparently share a drift isolate between such workers.
You can store the [`connectPort`](https://drift.simonbinder.eu/api/isolate/driftisolate/connectport) of a `DriftIsolate`
under a specific name to look it up later.
Other clients can use `DriftIsolate.fromConnectPort` to obtain a `DriftIsolate` from the name server, if one has been
registered.

Please note that, at the moment, Flutter still has some inherent problems with spawning isolates from background engines
that complicate this setup. Further, the `IsolateNameServer` is not cleared on a (stateless) hot reload, even though
the isolates are stopped and registered ports become invalid.
There is no reliable way to check if a `SendPort` is bound to an active `ReceivePort` or not.

Possible implementations of this pattern and associated problems are described in [this issue](https://github.com/simolus3/moor/issues/567#issuecomment-934514380).
