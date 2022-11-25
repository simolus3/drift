---
data:
  title: Isolates
  description: Using drift databases on a background isolate
template: layouts/docs/single
---

Drift can transparently run your queries in a background isolate to keep the foreground
free for other tasks. This is especially helpful for Flutter, where using a background isolate
helps reduce skipped frames.

With Drift's isolate setup, you only need to change how you _open_ your database. Internally,
Drift will apply its magic and send all database operations to an internal server running on
a background isolate. Zero code changes are needed for queries!

{% block "blocks/alert" title="Drift isolate - key points" color="success" %}

- Drift isolates have two primary use cases: To reduce the workload on your main
  isolate by running queries in the background; or to seamlessly share a stateful
  drift database between two isolates.
- You can see [this example](https://github.com/simolus3/drift/blob/develop/examples/app/lib/database/connection/native.dart)
  (and the rest of that small project) for a working setup using drift isolates.
- Internally, a drift isolate is an in-process database server receiving queries to
  execute through [`ReceivePort`s](https://api.dart.dev/stable/2.18.2/dart-isolate/ReceivePort-class.html).
  Drift hides the complexity of managing and talking to this server from you.
- You can use isolates and drift together without using a `DriftIsolate`! Are
  `DriftIsolate` just lets two isolates talk to the exact same drift database
  connection. If your isolates can have separate database connections, simply open
  your database on each isolate independently. There's no need for a `DriftIsolate`
  in that case.
- Drift's isolate implementation is generic enough to work over any reliable
  communication channel: You can also share a drift database between web workers
  or even over a TCP socket! For details, see the platform-independent [remote](https://pub.dev/documentation/drift/latest/drift.remote/drift.remote-library.html)
  library.
{% endblock %}

{% assign snippets = 'package:drift_docs/snippets/isolates.dart.excerpt.json' | readString | json_decode %}

## Simple setup

Starting from Drift version 2.3.0, using drift isolates has been greatly
simplified. Simply use `NativeDatabase.createInBackground` as a drop-in
replacement for the `NativeDatabase` you've been using before:

{% include "blocks/snippet" snippets = snippets name = 'simple' %}

In the common case where you only need a isolate for performance reasons, this
is as simple as it gets.
The rest of this article explains a more complex setup giving you full control
over the internal components making up a drift isolate. This is useful for
advanced use cases, including:

- Having two databases on different isolates which need to stay in sync.
- Sharing a drift database connection across different Dart or Flutter engines,
  like for a background service on Android.

In most other cases, simply using `NativeDatabase.createInbackground` works
great! It implements the same approach shared in this article, except that all
the complicated bits are hidden behind a simple method.

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

{% include "blocks/snippet" snippets = snippets name = 'database' %}

This setup is unfortunately necessary for backwards compatibility. A
`DatabaseConnection` and the `connect` constructor make it possible to share
query streams between isolates, the default constructor can't do this. In a
future drift reelase, this option will no longer be necessary.

After adding the `connect` constructor, you can launch a drift isolate to
connect to:

## Using drift in a background isolate {#using-moor-in-a-background-isolate}

With the database class ready, let's open it on a background isolate

{% include "blocks/snippet" snippets = snippets name = 'isolate' %}

If you need to construct the database outside of an `async` context, you can use the
`DatabaseConnection.delayed` constructor. In the example above, you
could synchronously obtain a `TodoDb` by using:

{% include "blocks/snippet" snippets = snippets name = 'delayed' %}

This can be helpful when using drift in dependency injection frameworks, since you have a way
to create the database instance synchronously.
Internally, drift will connect when the first query is sent to the database.

### Initialization on the main thread

At the moment, Flutter's platform channels are [not available on background isolates](https://github.com/flutter/flutter/issues/13937).
If you want to use functions like `getApplicationDocumentsDirectory` from `path_provider` to
construct the database's path, we'll have to use some tricks to avoid using platforms channels.
Here, we're going to start the isolate running the database manually. This allows us to pass additional
data that we calculated on the main thread.

{% include "blocks/snippet" snippets = snippets name = 'initialization' %}

Once again, you can use a `DatabaseConnection.delayed()` to obtain a database
connection for your database class:

{% include "blocks/snippet" snippets = snippets name = 'init_connect' %}

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

Multiple clients can connect to a single `DriftIsolate` multiple times. So, by
default, the isolate must outlive individual connections. Simply calling
`Database.close` on one of the clients won't stop the isolate (which could
interrupt other databases).
Instead, use `DriftIsolate.shutdownAll()` to close the isolate and all clients.
This call will release all resources used by the drift isolate.

In many cases, you know that only a single client will connect to the
`DriftIsolate` (for instance because you're spawning a new `DriftIsolate` when
opening a database). In this case, you can set the `singleClientMode: true`
parameter on `connect()`.
With this parameter, closing the single connection will also fully dispose the
drift isolate.

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
database is going to be slightly slower! There's a overhead involved in sending data between
isolates, and that's exactly what drift has to do internally. If you're not running into dropped
frames because of drift, using a background isolate is probably not necessary for your app.
However, isolate performance has dramatically improved in recent Dart and Flutter versions.

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

Possible implementations of this pattern and associated problems are described in [this issue](https://github.com/simolus3/drift/issues/567#issuecomment-934514380).
