---
title: "Supported platforms"
description: All platforms supported by moor, and how to use them
---

Being built ontop of the sqlite3 database, moor can run on almost every Dart platform.
Since the initial release of moor, the Dart and Flutter ecosystems have changed a lot.
For instance, `dart:ffi` wasn't a thing when moor first came out, and now it's the basis
for moor's most popular implemention.
To clear confusion about different moor packages and when to use them, this document
lists all supported platforms and how to use moor when building apps for them.

To achive platform independence, moor separates its core apis from a platform-specific
database implementation. The core apis are pure-Dart and run on all Dart platforms, even
outside of Flutter. When writing moor apps, prefer to mainly use the apis in 
`package:moor/moor.dart` as they are guaranteed to work across all platforms.
Depending on your platform, you can choose a different `QueryExecutor`.

## Mobile (Android and iOS)

There are two moor implementations for mobile that you can use:

### using `moor_flutter`

The original [`moor_flutter`](https://pub.dev/packages/moor_flutter) package uses `sqflite` and
only works on Android and iOS.
For new projects, we generally recommend the newer ffi-based implementation, but `moor_flutter`
is still maintained and suppported.

### using `moor/ffi`

The new `package:moor/ffi.dart` implementation uses `dart:ffi` to bind to sqlite3 on Android and iOS.
This is the recommended approach for newer projects as described in the [getting started]({{<relref "Getting started/_index.md">}}) guide.

To ensure that your app ships with the latest sqlite3 version, also add a dependency to the `sqlite3_flutter_libs`
package when using `package:moor/ffi.dart`!

## Web

_Main article: [Web]({{<relref "Other engines/web.md">}})_

For apps that run on the web, you can use moor's experimental web implementation, located
in `package:moor/moor_web.dart`.
As it binds to [sql.js](https://github.com/sql-js/sql.js), special setup is required. Please
read the main article for details.

## Desktop

Moor also supports all major Desktop operating systems where Dart runs on by using the 
`VmDatabase` from `package:moor/ffi.dart`. Depending on your operating system, further
setup might be required:

### Windows

On Windows, you can [download sqlite](https://www.sqlite.org/download.html) and extract
`sqlite3.dll` into a folder that's in your `PATH` environment variable to use moor.

You can also ship a custom `sqlite3.dll` along with your app. See the section below for
details.

### Linux

On most distributions, `libsqlite3.so` is installed already. If you only need to use moor for
development, you can just install the sqlite3 libraries. On Ubuntu and other Debian-based
distros, you can install the `libsqlite3-dev` package for this. Virtually every other distribution
will also have a prebuilt package for sqlite.

You can also ship a custom `libsqlite3.so` along with your app. See the section below for
details.

### macOS

This one is easy! Just use the `VmDatabase` from `package:moor/ffi.dart`. No further setup is
necessary. 

If you need a custom sqlite3 library, or want to make sure that your app will always use a
specific sqlite3 version, you can also ship that version with your app.

### Bundling sqlite with your app

If you don't want to use the `sqlite3` version from the operating system (or if it's not
available), you can also ship `sqlite3` with your app.
The best way to do that depends on how you ship your app. Here, we assume that you can
install the dynamic library for `sqlite` next to your application executable.

This example shows how to do that on Linux, by using a custom `sqlite3.so` that we assume
lives next to your application:

```dart
import 'dart:ffi';
import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3/open.dart';

void main() {
  open.overrideFor(OperatingSystem.linux, _openOnLinux);

  // After setting all the overrides, you can use moor!
}

DynamicLibrary _openOnLinux() {
  final script = File(Platform.script.toFilePath());
  final libraryNextToScript = File('${script.parent.path}/sqlite3.so');
  return DynamicLibrary.open(libraryNextToScript.path);
}
// _openOnWindows could be implemented similarly by opening `sqlite3.dll`
```

Be sure to use moor _after_ you set the platform-specific overrides.
