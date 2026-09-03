---

title: Supported platforms
description: All platforms supported by drift, and how to use them

---

Being built on top of the sqlite3 database, drift can run on almost every Dart platform.
Since the initial release, the Dart and Flutter ecosystems have changed a lot.
To clear confusion about different drift packages and when to use them, this document
lists all supported platforms and how to use drift when building apps for them.

To achieve platform independence, drift separates its core apis from a platform-specific
database implementation. The core apis are pure-Dart and run on all Dart platforms, even
outside of Flutter. When writing drift apps, prefer to mainly use the apis in
`package:drift/drift.dart` as they are guaranteed to work across all platforms.
Depending on your platform, you can choose a different `QueryExecutor` - the interface
binding the core drift library with native databases.

## Overview

This table list all supported drift implementations and on which platforms they run on.

| Implementation                                      | Supported platforms                 | Notes                                                                                                                                                                                                                                            |
| --------------------------------------------------- | ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `SqfliteQueryExecutor` from `package:drift_sqflite` | Android, iOS                        | Uses platform channels, Flutter only, no isolate support, doesn't support `flutter test`. Formerly known as `moor_flutter`                                                                                                                       |
| `NativeDatabase` from `package:drift/native.dart`   | Android, iOS, Windows, Linux, macOS | No further setup is required. Usage in a [isolate](../isolates.md) is recommended. Formerly known as `package:moor/ffi.dart`. |
| `WasmDatabase` from `package:drift/wasm.dart`       | Web                                 | Works with or without Flutter. A bit of [additional setup](web.md) is required.                                                                                                                                                                  |
| `WebDatabase` from `package:drift/web.dart`         | Web                                 | Deprecated in favor of `WasmDatabase`.                                                                                                                                                                                                           |

To support all platforms in a shared codebase, you only need to change how you open your database, all other usages can stay the same.
[This repository](https://github.com/simolus3/drift/tree/develop/examples/app) gives an example on how to do that with conditional imports.

## Mobile (Android and iOS)

There are two drift implementations for mobile that you can use:

### using `drift_sqflite`

`drift_sqflite` (formerly known as `moor_flutter`) is a package using the `sqflite` package to
provide a drift database implementation.
They use Flutter's package channels and support both Android and iOS. They don't work in Dart
projects not using flutter.

For new projects, we generally recommend the newer ffi-based implementation, but `drift_sqflite`
is maintained and supported too.

### using `drift/native`

The new `package:drift/native.dart` implementation uses `dart:ffi` to bind to sqlite3's native C apis.
This is the recommended approach for newer projects as described in the [getting started](../setup.md) guide.

Starting with version `3.0.0` of the `sqlite3` package (that drift depends on), a recent version of SQLite is automatically
bundled with your Flutter app.
More information about that mechanism and how to configure it is available [here](https://pub.dev/documentation/sqlite3/latest/topics/hook-topic.html).


!!! note "A note on ffi and Android"

    `package:drift/native.dart` is the recommended drift implementation for new Android apps.
    However, there are some smaller issues on some devices that you should be aware of:

    - Out of memory errors for very complex queries: Since the regular tmp directory isn't available on Android, you need to inform
    sqlite3 about the right directory to store temporary data. See [this comment](https://github.com/simolus3/drift/issues/876#issuecomment-710013503)
    for an example on how to do that.

## Web

_Main article: [Web](web.md)_

Drift runs on the web by compiling sqlite3 to a WebAssembly module. This database
can be accessed using a `WasmDatabase` in `package:drift/wasm.dart`.
For optimal support across different browsers, a worker script and some additional
setup is required. The main article explains how to set up drift to work on the web.

## Desktop

Drift also supports all major Desktop operating systems where Dart runs on by using the
`NativeDatabase` from `package:drift/native.dart`.

Starting from drift version 2.32.0 depending on versions 3.x of the `sqlite3` package,
no further setup is required and an up-to-date copy of SQLite will automatically be
bundled with your app.
See [sqlite3 build hooks](https://pub.dev/documentation/sqlite3/latest/topics/hook-topic.html)
for more information.

It is no longer necessary to depend on `sqlite3_flutter_libs` or `sqlcipher_flutter_libs`, you
can remove these dependencies.
