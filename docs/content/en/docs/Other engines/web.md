---
title: Web support
url: /web
description: Experimental support for moor and webapps.
---

Starting from moor `1.6`, you can experimentally use moor in Dart webapps. Moor web supports 
Flutter Web, AngularDart, plain `dart:html` or any other web framework.

## Getting started
Instead of depending on `moor_flutter` in your pubspec, you need to depend on on `moor` directly. Apart from that, you can
follow the [getting started guide]({{ site.common_links.getting_started | absolute_url }}).
Also, instead of using a `FlutterQueryExecutor` in your database classes, you can use a `WebDatabase` executor:
```dart
import 'package:moor/moor_web.dart';

@UseMoor(tables: [Todos, Categories])
class MyDatabase extends _$MyDatabase {
  // here, "app" is the name of the database - you can choose any name you want
  MyDatabase() : super(WebDatabase('app'));
```

Moor web is built on top of the [sql.js](https://github.com/kripken/sql.js/) library, which you need to include:
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
You can grab the latest version of `sql-wasm.js` and `sql-wasm.wasm` [here](https://github.com/kripken/sql.js/tree/master/dist)
and copy them into your `web` folder.

A full example that works on the web (and all other platforms) is available
[here](https://github.com/rodydavis/moor_shared).

## Gotchas
The database implementation uses WebAssembly, which needs to be supported by your browser. 
Also, make sure that your webserver serves the `.wasm` file as `application/wasm`, browsers
won't accept it otherwise.

## Sharing code between native apps and web
If you want to share your database code between native applications and webapps, just import the
basic `moor` library and make the `QueryExecutor` configurable:
```dart
// don't import moor_web.dart or moor_flutter/moor_flutter.dart in shared code
import 'package:moor/moor.dart';

@UseMoor(/* ... */)
class SharedDatabase extends _$MyDatabase {
    SharedDatabase(QueryExecutor e): super(e);
}
```
With native Flutter, you can create an instance of your database with
```dart
import 'package:moor_flutter/moor_flutter.dart';
SharedDatabase constructDb() {
    return SharedDatabase(FlutterQueryExecutor.inDatabaseFolder(path: 'db.sqlite'));
}
```
On the web, you can use
```dart
import 'package:moor/moor_web.dart';
SharedDatabase constructDb() {
    return SharedDatabase(WebDatabase('db'));
}
```

## Debugging
You can see all queries sent from moor to the underlying database engine by enabling the `logStatements`
parameter on the `WebDatabase` - they will appear in the console.
When you have assertions enabled (e.g. in debug mode), moor will expose the underlying 
[database](http://kripken.github.io/sql.js/documentation/#http://kripken.github.io/sql.js/documentation/class/Database.html)
object via `window.db`. If you need to quickly run a query to check the state of the database, you can use
`db.exec(sql)`.
If you need to delete your databases, there stored using local storage. You can clear all your data with `localStorage.clear()`.

Web support is experimental at the moment, so please [report all issues](https://github.com/simolus3/moor/issues/new) you find.

## Using IndexedDb

The default `WebDatabase` uses local storage to store the raw sqlite database file. On browsers that support it, you can also
use `IndexedDb` to store that blob. In general, browsers allow a larger size for `IndexedDb`. The implementation is also more
performant, since we don't have to encode binary blobs as strings.

To use this implementation on browsers that support it, replace `WebDatabase(name)` with:

```dart
WebDatabase.withStorage(MoorWebStorage.indexedDbIfSupported(name))
```

Moor will automatically migrate data from local storage to `IndexeDb` when it is available.