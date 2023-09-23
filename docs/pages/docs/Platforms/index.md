---
data:
  title: "Supported platforms"
  description: All platforms supported by drift, and how to use them
  weight: 8
template: layouts/docs/list
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

| Implementation | Supported platforms | Notes |
|----------------|---------------------|-------|
| `SqfliteQueryExecutor` from `package:drift_sqflite` | Android, iOS | Uses platform channels, Flutter only, no isolate support, doesn't support `flutter test`. Formerly known as `moor_flutter` |
| `NativeDatabase` from `package:drift/native.dart` | Android, iOS, Windows, Linux, macOS | No further setup is required for Flutter users. For support outside of Flutter, or in `flutter test`, see the [desktop](#desktop) section below. Usage in a [isolate]({{ '../isolates.md' | pageUrl }}) is recommended. Formerly known as `package:moor/ffi.dart`. |
| `WasmDatabase` from `package:drift/wasm.dart` | Web | Works with or without Flutter. A bit of [additional setup]({{ 'web.md' | pageUrl }}) is required. |
| `WebDatabase` from `package:drift/web.dart` | Web | Deprecated in favor of `WasmDatabase`. |

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
is maintaned and supported too.

### using `drift/native`

The new `package:drift/native.dart` implementation uses `dart:ffi` to bind to sqlite3's native C apis.
This is the recommended approach for newer projects as described in the [getting started]({{ "../setup.md" | pageUrl }}) guide.

To ensure that your app ships with the latest sqlite3 version, also add a dependency to the `sqlite3_flutter_libs`
package when using `package:drift/native.dart`!
`sqlite3_flutter_libs` will configure your app to use a fixed sqlite3 version on Android, iOS and macOS.
It only applies to your full Flutter app though, it can't override the sqlite3 version when running tests
with `flutter test`.

{% block "blocks/alert" title="A note on ffi and Android" %}
`package:drift/native.dart` is the recommended drift implementation for new Android apps.
However, there are some smaller issues on some devices that you should be aware of:

- Using `sqlite3_flutter_libs` will include prebuilt binaries for 32-bit `x86` devices which you
  probably won't need. You can apply a [filter](https://github.com/simolus3/sqlite3.dart/tree/master/sqlite3_flutter_libs#included-platforms)
  in your `build.gradle` to remove those binaries.
- Opening `libsqlite3.so` fails on some Android 6.0.1 devices. This can be fixed by setting
  `android.bundle.enableUncompressedNativeLibs=false` in your `gradle.properties` file.
  Note that this will increase the disk usage of your app. See [this issue](https://github.com/simolus3/drift/issues/895#issuecomment-720195005)
  for details.
- Out of memory errors for very complex queries: Since the regular tmp directory isn't available on Android, you need to inform
  sqlite3 about the right directory to store temporary data. See [this comment](https://github.com/simolus3/drift/issues/876#issuecomment-710013503)
  for an example on how to do that.
{% endblock %}

## Web

_Main article: [Web]({{ "web.md" | pageUrl }})_

Drift runs on the web by compiling sqlite3 to a WebAssembly module. This database
can be accessed using a `WasmDatabase` in `package:drift/wasm.dart`.
For optimal support across different browsers, a worker script and some additional
setup is required. The main article explains how to set up drift to work on the web.

## Desktop

Drift also supports all major Desktop operating systems where Dart runs on by using the
`NativeDatabase` from `package:drift/native.dart`. Depending on your operating system, further
setup might be required:

### Windows

For Flutter apps, depending on the `sqlite3_flutter_libs` package is enough. It will automatically
bundle the latest sqlite3 version with your app as a DLL, and drift will automatically use that
version.

If you don't want to use `sqlite3_flutter_libs`, or if you're not running as a Flutter app
(keep in mind that `flutter test` does not run as a full Flutter app!), you can [download sqlite](https://www.sqlite.org/download.html)
and extract`sqlite3.dll` into a folder that's in your `PATH` environment variable to use drift.

You can also ship a custom `sqlite3.dll` along with your app. See the section below for
details.

### Linux

When depending on `sqlite3_flutter_libs` in your pubspec and using Flutter, no additional setup
is necessary.
When not running as a Flutter app (this includes `flutter test`!), you need to either use a
`sqlite3` build from your distribution or include a custom `libsqlite3.so`.

On most distributions, `libsqlite3.so` is installed already. If you only need to use drift for
development, you can just install the sqlite3 libraries. On Ubuntu and other Debian-based
distros, you can install the `libsqlite3-dev` package for this. Virtually every other distribution
will also have a prebuilt package for sqlite.

You can also ship a custom `libsqlite3.so` along with your app. See the section below for
details.

### macOS

This one is easy! Just use the `NativeDatabase` from `package:drift/native.dart`. No further setup is
necessary.

If you need a custom sqlite3 library, or want to make sure that your app will always use a
specific sqlite3 version, you can also ship that version with your app.
When depending on `sqlite3_flutter_libs`, drift will automatically use that version which is
usually more recent than the `sqlite3` version that comes with macOS.
Again, note that this only works with full Flutter apps and not in say `flutter test`.

For tests or using a custom sqlite3 version without `sqlite3_flutter_libs`, see the following
section.

### Bundling sqlite with your app

If you don't want to use the `sqlite3` version from the operating system (or if it's not
available), you can also ship `sqlite3` with your app.
The best way to do that depends on how you ship your app. Here, we assume that you can
install the dynamic library for `sqlite` next to your application executable.

This example shows how to do that on Linux, by using a custom `sqlite3.so` that we assume
lives next to your application:

{% assign snippets = 'package:drift_docs/snippets/platforms/platforms.dart.excerpt.json' | readString | json_decode %}
{% include "blocks/snippet" snippets = snippets %}

Be sure to use drift _after_ you set the platform-specific overrides.
When you use drift in [another isolate]({{ '../isolates.md' | pageUrl }}),
you'll also need to apply the opening overrides on that background isolate.
You can call them in the isolate's entrypoint before using any drift apis.

For standard Flutter tests running in a Dart VM without native plugins, you can use a
`flutter_test_config.dart` file to ensure that a recent version of sqlite3 is available.
An example for this is available [here](https://github.com/simolus3/drift/discussions/1745#discussioncomment-2326294).
For Dart tests, a similar logic could be put into a `setupAll` callback.
