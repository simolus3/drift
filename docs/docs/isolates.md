---
data:
  title: Isolates
  description: Accessing drift databases on multiple isolates.
  weight: 10
template: layouts/docs/single
path: docs/advanced-features/isolates/
---

{% assign snippets = 'package:drift_docs/snippets/isolates.dart.excerpt.json' | readString | json_decode %}

As sqlite3 is a synchronous C library, accessing the database from the main isolate
can cause blocking IO operations that lead to reduced responsiveness of your
application.
To resolve this problem, drift can spawn a long-running isolate to run SQL statements.
When following the recommended [getting started guide]({{ 'setup.md' | pageUrl }})
and using `NativeDatabase.createInBackground`, you automatically benefit from an isolate
drift manages for you without needing additional setup.
This page describes when advanced isolate setups are necessary, and how to approach them.

{% block "blocks/alert" title="When to use drift isolates" color="success" %}
- Drift already uses isolates with the default setups to avoid blocking the main
  isolate on synchronous IO.
- You can open two _independent_ drift databases on different isolates without
  any special setup or drift APIs too. These can even point to the same database
  file, but then stream queries won't synchronize between those independent
  instances.
- If you need to share a single drift database on multiple isolates, some setup
  is necessary. This is what drift's isolate APIs are for!
{% endblock %}

## Introduction

While the default setup is probably suitable for most apps, some scenarios require
complete additional over the way drift manages isolates.
In particular, some of these

- You want to use a drift isolate in `compute()`, `Isolate.run` or generally in other isolates.
- You need to access a drift database in a [background worker](https://pub.dev/packages/workmanager).
- You want to  control the way drift spawns isolates instead of using the default.

When you try to send a drift database instance across isolates, you will run into
an exception about sending an invalid object:

{% include "blocks/snippet" snippets = snippets name = 'invalid' %}

Unfortunately, there is no magic change drift could implement to make sending
databases over isolates feasible: There's simply too much mutable state needed
to implement features like stream queries or high-level transaction APIs.
However, with a little bit of additional setup, you can use drift APIs to obtain
two database instances that are synchronized by an isolate channel drift manages
for you. Writes on one database are readable on the other isolate and even update
stream queries. So essentially, you get one logical database instance shared
between isolates.

## Simple sharing

Starting from drift 2.5, running a short-lived computation workload on a separate
isolate is easily possible with `computeWithDatabase`.
This function helps spawn an isolate and opens another database instance on that
isolate. Since the background database instance needs to talk to the main instance
on the foreground isolate for synchronization, you need a constructor on your
database class that can take a custom `QueryExecutor`, the class used by drift
to represent lower-level databases:

{% include "blocks/snippet" snippets = snippets name = 'database-definition' %}

{% include "blocks/snippet" snippets = snippets name = 'compute' %}

As the example shows, `computeWithDatabase` is an API useful to run heavy tasks,
like inserting a large amount of batch data, into a database.

Internally, `computeWithDatabase` does the following:

1. It sets up a pair of `SendPort` / `ReceivePort`s over which database calls
   are relayed.
2. It spawns a new isolate with `Isolate.run` and creates a raw database
   connection based on those ports.
3. The new isolate invokes the `connect` callback to create a second instance
   of your database class that talks to the main instance over isolate ports.
4. The `computation` callback is invoked.
5. Transparently, drift also takes care of winding down the connection afterwards.

If you don't want drift to spawn the isolate for you, for instance because you want
to use `compute` instead of `Isolate.run`, you can also do that manually with the
`serializableConnection()` API:

{% include "blocks/snippet" snippets = snippets name = 'custom-compute' %}

## Manually managing drift isolates

Instead of using functions like `NativeDatabase.createInBackground` or
`computeWithDatabase`, you can also create database connections that can be
shared across isolates manually.

Drift exposes the `DriftIsolate` class, which is a reference to an internal
database server you can access on other isolates.
Creating a `DriftIsolate` server is possible with `DriftIsolate.spawn()`:

{% include "blocks/snippet" snippets = snippets name = 'driftisolate-spawn' %}

If you want to spawn the isolate yourself, that is possible too:

{% include "blocks/snippet" snippets = snippets name = 'custom-spawn' %}

After creating a `DriftIsolate` server, you can use `connect()` to connect
to it from different isolates:

{% include "blocks/snippet" snippets = snippets name = 'isolate' %}

If you need to construct the database outside of an `async` context, you can use the
`DatabaseConnection.delayed` constructor. In the example above, you
could synchronously obtain a `MyDatabase` instance by using:

{% include "blocks/snippet" snippets = snippets name = 'delayed' %}

This can be helpful when using drift in dependency injection frameworks, since you have a way
to create the database instance synchronously.
Internally, drift will connect when the first query is sent to the database.

### Workaround for old Flutter versions

Before Flutter 3.7, platforms channels weren't [available on background isolates](https://github.com/flutter/flutter/issues/13937).
So, if functions like `getApplicationDocumentsDirectory` from `path_provider`
are used to construct the path to the database, some tricks were necessary.
This section describes a workaround to start the isolate running the database
manually. This allows passing additional data that can be computed on the main
isolate, using platform channels.

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
In this case, using the `DriftIsolate` APIs may be an overkill - `NativeDatabase.createInBackground` will
do the exact same thing for you.

__One executor isolate, multiple client isolates__: The `DriftIsolate` handle can be sent across multiple
isolates, each of which can use `DriftIsolate.connect` on their own. This is useful to implement
a setup where you have three or more threads:

- The drift executor isolate
- A foreground isolate, probably for Flutter
- Another background isolate, which could be used for networking or other long-running expensive tasks.

You can then read data from the foreground isolate or start query streams, similar to the example
above. The background isolate would _also_ call `DriftIsolate.connect` and create its own instance
of the generated database class. Writes to one database will be visible to the other isolate and
also update query streams.

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
