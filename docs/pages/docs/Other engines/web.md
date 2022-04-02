---
data:
  title: Web
  description: Experimental support for drift and webapps.
template: layouts/docs/single
path: web/
---

You can experimentally use drift in Dart webapps. Drift web supports 
Flutter Web, AngularDart, plain `dart:html` or any other web framework.

## Getting started

From a perspective of the Dart code used, drift on the web is similar to drift on other platforms.
You can follow the [getting started guide]({{ '../Getting started/index.md' | pageUrl }}) for general
information on using drift.

Instead of using a `NativeDatabase` in your database classes, you can use a `WebDatabase` executor:

```dart
import 'package:drift/web.dart';

@DriftDatabase(tables: [Todos, Categories])
class MyDatabase extends _$MyDatabase {
  // here, "app" is the name of the database - you can choose any name you want
  MyDatabase() : super(WebDatabase('app'));
```

Drift web is built on top of the [sql.js](https://github.com/sql-js/sql.js/) library, which you need to include:
```html
<!doctype html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <script defer src="sql-wasm.js"></script>
    <script defer src="main.dart.js" type="application/javascript"></script>
</head>
<body></body>
</html>
```
You can grab the latest version of `sql-wasm.js` and `sql-wasm.wasm` [here](https://github.com/sql-js/sql.js/releases)
and copy them into your `web` folder.

A full example that works on the web (and all other platforms) is available
[here](https://github.com/rodydavis/moor_shared).

## Gotchas
The database implementation uses WebAssembly, which needs to be supported by your browser. 
Also, make sure that your webserver serves the `.wasm` file as `application/wasm`, browsers
won't accept it otherwise.

## Sharing code between native apps and web

If you want to share your database code between native applications and webapps, just import the
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
  return SharedDatabase(WebDatabase('db'));
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

A ready example of this construct can also be found [here](https://github.com/rodydavis/moor_shared/blob/master/lib/src/database/database/unsupported.dart).

## Debugging
You can see all queries sent from drift to the underlying database engine by enabling the `logStatements`
parameter on the `WebDatabase` - they will appear in the console.
When you have assertions enabled (e.g. in debug mode), drift will expose the underlying 
[database](https://sql.js.org/documentation/Database.html)
object via `window.db`. If you need to quickly run a query to check the state of the database, you can use
`db.exec(sql)`.
If you need to delete your databases, there stored using local storage. You can clear all your data with `localStorage.clear()`.

Web support is experimental at the moment, so please [report all issues](https://github.com/simolus3/drift/issues/new) you find.

## Using IndexedDb

The default `WebDatabase` uses local storage to store the raw sqlite database file. On browsers that support it, you can also
use `IndexedDb` to store that blob. In general, browsers allow a larger size for `IndexedDb`. The implementation is also more
performant, since we don't have to encode binary blobs as strings.

To use this implementation on browsers that support it, replace `WebDatabase(name)` with:

```dart
WebDatabase.withStorage(await DriftWebStorage.indexedDbIfSupported(name))
```

Drift will automatically migrate data from local storage to `IndexedDb` when it is available.

### Using web workers

You can offload the database to a background thread by using 
[Web Workers](https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API).
Drift also supports [shared workers](https://developer.mozilla.org/en-US/docs/Web/API/SharedWorker),
which allows you to seamlessly synchronize query-streams and updates across multiple tabs!

Since web workers can't use local storage, you need to use `DriftWebStorage.indexedDb` instead of
the regular implementation.

The following example is meant to be used with a regular Dart web app, compiled using
[build_web_compilers](https://pub.dev/packages/build_web_compilers).

To write a web worker that will serve requests for drift, create a file called `worker.dart` in 
the `web/` folder of your app. It could have the following content:

```dart
import 'dart:html';

import 'package:drift/drift.dart';
import 'package:drift/web.dart';
import 'package:drift/remote.dart';

void main() {
  final self = SharedWorkerGlobalScope.instance;
  self.importScripts('sql-wasm.js');

  final db = WebDatabase.withStorage(DriftWebStorage.indexedDb('worker',
      migrateFromLocalStorage: false, inWebWorker: true));
  final server = DriftServer(DatabaseConnection.fromExecutor(db));

  self.onConnect.listen((event) {
    final msg = event as MessageEvent;
    server.serve(msg.ports.first.channel());
  });
}
```

For more information on this api, see the [remote API](https://pub.dev/documentation/drift/latest/remote/remote-library.html).

Connecting to that worker is very simple with drift's web and remote apis. In your regular app code (outside of the worker),
you can connect like this:

```dart
import 'dart:html';

import 'package:drift/remote.dart';
import 'package:drift/web.dart';
import 'package:web_worker_example/database.dart';

DatabaseConnection connectToWorker() {
    final worker = SharedWorker('worker.dart.js');
    return remote(worker.port!.channel());
}
```

You can pass that `DatabaseConnection` to your database by enabling the
`generate_connect_constructor` build option.
For more information on the `DatabaseConnection` class, see the documentation on
[isolates]({{ "../Advanced Features/isolates.md" | pageUrl }}).

A small, but working example is available under [examples/web_worker_example](https://github.com/simolus3/drift/tree/develop/examples/web_worker_example)
in the drift repository.

### Flutter
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

## New web backend {#drift-wasm}

__Warning__: This new backend is currently in a very experimental state and not suitable for production use.

Starting from version `1.6.0`, drift supports the new `package:drift/wasm.dart` backend for web apps.
It binds to a sqlite3 WebAssembly module directly, without requireing an external JavaScript library.
Unlike sql.js, which uses Emscripten, the new backend uses a custom [sqlite3 VFS](https://www.sqlite.org/vfs.html)
and doesn't require any dependencies apart from sqlite3 itself.
The intention is that this build can be optimized for Dart-typical use-cases. For instance, the sql.js backend
needs to close and re-open the database connection for every save. The new backend can just use a custom
virtual file system that sqlite3 will then use internally.

As this version of sqlite3 was compiled with a custom VFS, you can't re-use the WebAssembly module from sql.js.
Instead, grab a sqlite3.wasm file from the [releases](https://github.com/simolus3/sqlite3.dart/releases) of the
`sqlite3` pub package and put this file in your `web/` folder.

With this setup, sqlite3 can be used on the web without an external library:

{% assign snippets = 'package:moor_documentation/snippets/engines/web_wasm.dart.excerpt.json' | readString | json_decode %}
{% include "blocks/snippet" snippets = snippets %}

This snippet also works in a service worker.

If you're running into any issues with the new backend, please post them [here](https://github.com/simolus3/sqlite3.dart/issues).