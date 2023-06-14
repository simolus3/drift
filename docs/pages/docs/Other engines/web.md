---
data:
  title: Web
  description: Drift support in Flutter and Dart web apps.
template: layouts/docs/single
path: web/
---

{% assign snippets = "package:drift_docs/snippets/engines/web.dart.excerpt.json" | readString | json_decode %}


Using modern browser APIs such as WebAssembly and the Origin-Private File System API,
you can use drift databases when compiling your apps to the web.
Just like the core drift APIs, web support is platform-agnostic:
Drift web supports Flutter Web, AngularDart, plain `dart:html` or any other Dart web framework.

{% block "blocks/alert" title="Compatibility check"  %}
This page includes a tiny drift database compiled to JavaScript.
You can use it to verify drift works in the Browsers you want to target.
Clicking on the button will start a feature detection run, so you can see which file system
implementation drift would pick on this browser and which web APIs are missing.

<button class="btn btn-light" id="drift-compat-btn">Check compatibility</button>

<pre id="drift-compat-results">
Compatibility check not started yet
</pre>

More information about these results is available [below](#storages).
{% endblock %}

## Getting started

### Prerequisites

On all platforms, drift requires access to [sqlite3](https://sqlite.org/index.html), the popular
datase system written as a C library.
On native platforms, drift can use the sqlite3 library from your operating system. Flutter apps
typically include a more recent version of that library with the `sqlite3_flutter_libs` package too.

Web browsers don't have builtin access to the sqlite3 library, so it needs to be included with your app.
The `sqlite3` Dart package (used by drift internally) contains a toolchain to compile sqlite3 to WebAssembly
so that it can be used in browsers. You can grab a `sqlite3.wasm` file from [its releases page](https://github.com/simolus3/sqlite3.dart/releases).
This file needs to be put into the `web/` directory of your app.

Drift on the web also requires you to include a portion of drift as a web worker. This worker will be used to
host your database in a background thread, improving performance of your website. In some [storage implementations](#storages),
the worker is also responsible for sharing your database between different tabs in real-time.
You can compile this worker yourself, [grab one from drift releases](https://github.com/simolus3/drift/releases) or take
the [latest one powering this website]({{ '/worker.dart.js' | absUrl }}).

In the end, your `web/` directory may look like this:

```
web/
├── favicon.png
├── index.html
├── manifest.json
├── drift_worker.dart.js
└── sqlite3.wasm
```

#### Additional headers

On browsers that support it, drift uses the origin-private part of the [FileSystem Access API](https://developer.mozilla.org/en-US/docs/Web/API/File_System_Access_API) to store databases efficiently.
As parts of that API are asynchronous, and since sqlite3 expectes a synchronous file system, we need to
use two workers with shared memory and `Atomics.wait`/`notify`.
Just like the official sqlite3 port to the web, __this requires your website to be served with two special headers__:

- `Cross-Origin-Opener-Policy`: Needs to be set to `same-origin`.
- `Cross-Origin-Embedder-Policy`: Needs to be set to `require-corp` or `credentialless`.

For more details, see the [security requirements](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/SharedArrayBuffer) explained by MDN, and the [documentation on web.dev](https://web.dev/coop-coep/).
Unfortunately, there's no way (that I'm aware of) to add these headers onto `flutter run`'s web server.
Drift will fall back to a less reliable implementation in that case (see [storages](#storages)),
but we recommend researching and enabling these headers in production if possible.

### Setup in Dart

From a perspective of the Dart code used, drift on the web is similar to drift on other platforms.
You can follow the [getting started guide]({{ '../Getting started/index.md' | pageUrl }}) for general
information on using drift.

Instead of using a `NativeDatabase` in your database classes, you can use `WasmDatabase` optimized for
the web:

{% include "blocks/snippet" snippets = snippets name = "connect" %}

When you call `WasmDatabase.open`, drift will automatically find a suitable persistence implementation
supported by the current browser.

A full example that works on the web (and all other platforms supported by drift) is available
[here](https://github.com/simolus3/drift/tree/develop/examples/app).

## Sharing code between native apps and web

If you want to share your database code between native applications and web apps, just import the
basic `drift/drift.dart` library into your database file.
And instead of passing a `NativeDatabase` or `WebDatabase` to the `super` constructor, make the
`QueryExecutor` customizable:

```dart
// don't import drift/web.dart or drift/native.dart in shared code
import 'package:drift/drift.dart';

@DriftDatabase(/* ... */)
class SharedDatabase extends _$MyDatabase {
    SharedDatabase(QueryExecutor e): super(e);
}
```

In native Flutter apps, you can create an instance of your database with

```dart
// native.dart
import 'package:drift/native.dart';

SharedDatabase constructDb() {
  final db = LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
  return SharedDatabase(db);
}
```

On the web, you can use

```dart
// web.dart
import 'package:drift/web.dart';

SharedDatabase constructDb() {
  return SharedDatabase(connectOnWeb());
}
```

Finally, we can use [conditional imports](https://dart.dev/guides/libraries/create-library-packages#conditionally-importing-and-exporting-library-files)
to automatically pick the right `constructDb` function based on where your app runs.
To do this, first create a `unsupported.dart` default implementation:

```dart
// unsupported.dart
SharedDatabase constructDb() => throw UnimplementedError();
```

Now, we can use conditional imports in a `shared.dart` file to export the correct function:

```dart
// shared.dart
export 'unsupported.dart'
  if (dart.library.ffi) 'native.dart'
  if (dart.library.html) 'web.dart';
```

A ready example of this construct can also be found [here](https://github.com/simolus3/drift/blob/develop/examples/app/lib/database/connection/connection.dart).

## Supported storage implementations {#storages}

When opening a database, drift determines the state of a number of web APIs in the current browser.
It then picks a suitable database storage based on what the current browser supports.
The following implementation strategies are supported by drift (listed in order of descending preference).
You can view the chosen strategy via the `WasmDatabaseResult.chosenImplementation` returned by
`WasmDatabase.open`.

1. `opfsShared`: Uses the origin-private filesystem access API in a shared web worker.
   As this API is only available in dedicated web workers, this requires shared workers to be able to
   spawn dedicated workers. While allowed by the web standards, this is only implemented by Firefox.
2. `opfsLocks`: Uses the origin-private filesystem access API, but without shared workers.
   This requires the [COOP and COEP headers](#additional-headers).
3. `sharedIndexedDb`: Uses IndexedDB to store chunks of data, the database is hosted in a shared web worker.
4. `unsafeIndexedDb`: This also uses the IndexedDB database, but without a shared worker or another
   means of synchronization between tabs. In this mode, __it is not safe for multiple tabs of your app
   to access the same database__.
   While this was the default mode used by earlier implementations of drift for the web, we now try to
   avoid it and it will not be used on modern browsers.
5. `inMemory`: When no persistence API is available, drift will fall back to an in-memory database.

The missing browser APIs contributing to a specific implementation being chosen are available in
`WasmDatabaseResult.missingFeatures`.
There's nothing your app or drift could do about them. If persistence is important to your app
and drift has chosen the `unsafeIndexedDb` or the `inMemory` implementation due to a lack of proper
persistence support, you may want to show a warning to the user explaining that they have to upgrade
their browser.

### Migrating from existing web databases

`WasmDatabase.open` is drift's stable web API, which has been built with the lessons learned from previous
web APIs available in drift (that have always been marked as `@experimental`). You can use `WasmDatabase.open`
to replace the following drift APIs:

1. The sql.js-based implementation in `package:drift/web.dart`.
2. Custom `WasmDatabase` constructions that manually load sqlite3.
3. Custom worker setups created with `package:drift/web/worker.dart`.

Let's start with the good news: After migrating to `WasmDatabase.open`, drift will manage workers for you.
It automatically uses the best worker setup supported by the current browsers, enabling the use of shared
and dedicated web workers where appropriate.
So the migration from `package:drift/web/worker.dart` is to just stop using that API, since you get all of
its features out of the box with `WasmDatabase.open`.

#### Migrating from custom `WasmDatabase`s

In older drift versios, you may have used a custom setup that loaded the WASM binary manually, created
a `CommonSqlite3` instance with it and passed that to `WasmDatabase`.

{% include "blocks/snippet" snippets = snippets name = "migrate-wasm" %}

#### Migrating from `package:drift/web.dart`

To migrate from a `WebDatabase` to the new setup, you can use the `initializeDatabase` callback.
It is invoked when opening the database if no file exists yet. By loading the old database there,
it is migrated to the new format without data loss:

{% include "blocks/snippet" snippets = snippets name = "migrate-legacy" %}

In that snippet, `old_db` is the name previously passed to the `WebDatabase`.

## Legacy web support

Drift first gained its initial web support in 2019 by wrapping the sql.js JavaScript library.
This implementation, which is still supported today, relies on keeping an in-memory database that is periodically saved to local storage.
In the last years, development in web browsers and the Dart ecosystem enabled more performant approaches that are
unfortunately impossible to implement with the original drift web API.
This is the reason the original API is still considered experimental - while it will continue to be supported, it is now obvious that the new approach by `WasmDatabase.open` is sound and more efficient
than these implementations.
The original APIs are still documented on this page for your reference.

### Debugging
You can see all queries sent from drift to the underlying database engine by enabling the `logStatements`
parameter on the `WebDatabase` - they will appear in the console.
When you have assertions enabled (e.g. in debug mode), drift will expose the underlying
[database](https://sql.js.org/documentation/Database.html)
object via `window.db`. If you need to quickly run a query to check the state of the database, you can use
`db.exec(sql)`.
If you need to delete your databases, there stored using local storage. You can clear all your data with `localStorage.clear()`.

Web support is experimental at the moment, so please [report all issues](https://github.com/simolus3/drift/issues/new) you find.

### Using IndexedDb

The default `WebDatabase` uses local storage to store the raw sqlite database file. On browsers that support it, you can also
use `IndexedDb` to store that blob. In general, browsers allow a larger size for `IndexedDb`. The implementation is also more
performant, since we don't have to encode binary blobs as strings.

To use this implementation on browsers that support it, replace `WebDatabase(name)` with:

```dart
WebDatabase.withStorage(await DriftWebStorage.indexedDbIfSupported(name))
```

Drift will automatically migrate data from local storage to `IndexedDb` when it is available.


#### Using web workers

You can offload the database to a background thread by using 
[Web Workers](https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API).
Drift also supports [shared workers](https://developer.mozilla.org/en-US/docs/Web/API/SharedWorker),
which allows you to seamlessly synchronize query-streams and updates across multiple tabs!

Since web workers can't use local storage, you need to use `DriftWebStorage.indexedDb` instead of
the regular implementation.

The following example is meant to be used with a regular Dart web app, compiled using
[build_web_compilers](https://pub.dev/packages/build_web_compilers).
A Flutter port of this example is [part of the drift repository](https://github.com/simolus3/drift/tree/develop/examples/flutter_web_worker_example).

To write a web worker that will serve requests for drift, create a file called `worker.dart` in
the `web/` folder of your app. It could have the following content:

{% assign workers = 'package:drift_docs/snippets/engines/workers.dart.excerpt.json' | readString | json_decode %}

{% include "blocks/snippet" snippets = workers name = "worker" %}

For more information on this api, see the [remote API](https://pub.dev/documentation/drift/latest/remote/remote-library.html).

Connecting to that worker is very simple with drift's web and remote apis. In your regular app code (outside of the worker),
you can connect like this:

{% include "blocks/snippet" snippets = workers name = "client" %}

You can then open a drift database with that connection.
For more information on the `DatabaseConnection` class, see the documentation on
[isolates]({{ "../Advanced Features/isolates.md" | pageUrl }}).

A small, but working example is available under [examples/web_worker_example](https://github.com/simolus3/drift/tree/develop/examples/web_worker_example)
in the drift repository.

#### Flutter
Flutter users will have to use a different approach to compile service workers.
Flutter web doesn't compile `.dart` files in web folder and won't use `.js` files generated by
`build_web_compilers` either. Instead, we'll use Dart's build system to manually compile the worker to a
JavaScript file before using Flutter-specific tooling.

Example is available under [examples/flutter_web_worker_example](https://github.com/simolus3/drift/tree/develop/examples/flutter_web_worker_example)
in the drift repository.

First, add [build_web_compilers](https://pub.dev/packages/build_web_compilers) to the project:

```yaml
dev_dependencies:
  build_web_compilers: ^3.2.1
```

Inside a `build.yaml` file, the compilers can be configured to always use `dart2js` (a good choice for web workers).
Add these lines to `build.yaml`:

```yaml
targets:
  $default:
    builders:
      build_web_compilers:entrypoint:
        generate_for:
          - web/**.dart
        options:
          compiler: dart2js
        dev_options:
          dart2js_args:
            - --no-minify
        release_options:
          dart2js_args:
            - -O4
```

Nowm, run the compiler and copy the compiled worker JS files to `web/`:

```shell
#Debug mode
flutter pub run build_runner build --delete-conflicting-outputs -o web:build/web/
cp -f build/web/worker.dart.js web/worker.dart.js
```

```shell
#Release mode
flutter pub run build_runner build --release --delete-conflicting-outputs -o web:build/web/
cp -f build/web/worker.dart.js web/worker.dart.min.js
```

Finally, use this to connect to a worker:

```dart
import 'dart:html';

import 'package:drift/drift.dart';
import 'package:drift/remote.dart';
import 'package:drift/web.dart';
import 'package:flutter/foundation.dart';

DatabaseConnection connectToWorker(String databaseName) {
  final worker = SharedWorker(
      kReleaseMode ? 'worker.dart.min.js' : 'worker.dart.js', databaseName);
  return remote(worker.port!.channel());
}
```

You can pass that DatabaseConnection to your database by enabling the `generate_connect_constructor` build option.

### New web backend {#drift-wasm}

In recent versions, drift added support for a new backend exposed by the `package:drift/wasm.dart` library.
Unlike sql.js or the official sqlite3 WASM edition which both use Emscripten, this backend does not need any
external JavaScript sources.
All bindings, including a virtual filesystem implementation used to store your databases, are implemented in
Dart instead.

This approach enables optimizations making this backend more efficient that the existing web version of drift.
However, it should be noted that this backend is much newer and may potentially be less stable at the moment.
We encourage you to use it and report any issues you may find, but please keep in mind that it may have some
rough edges.

As this version of sqlite3 was compiled with a custom VFS, you can't re-use the WebAssembly module from sql.js.
Instead, grab a sqlite3.wasm file from the [releases](https://github.com/simolus3/sqlite3.dart/releases) of the
`sqlite3` pub package and put this file in your `web/` folder.

With this setup, sqlite3 can be used on the web without an external library:

This snippet also works in a service worker.

If you're running into any issues with the new backend, please post them [here](https://github.com/simolus3/sqlite3.dart/issues).
