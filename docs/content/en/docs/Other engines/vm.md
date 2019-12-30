---
title: Dart VM (Desktop support)
description: Run moor on both mobile and desktop
---

## Supported versions

At the moment, `moor_ffi` supports iOS, macOS and Android out of the box. Most Linux
Distros have sqlite available as a shared library, those are supported as well. 

If you're shipping apps for Windows and Linux, it is recommended that you bundle a
`sqlite3.so` and `sqlite3.dll` file with your app. You can then make `moor_ffi`
support your setup by running this code before opening the database:

```dart
import 'dart:ffi';
import 'dart:io';
import 'package:moor_ffi/database.dart';
import 'package:moor_ffi/open_helper.dart';

void main() {
  open.overrideFor(OperatingSystem.linux, _openOnLinux);

  final db = Database.memory();
  db.close();
}

DynamicLibrary _openOnLinux() {
  final script = File(Platform.script.toFilePath());
  final libraryNextToScript = File('${script.path}/sqlite3.so');
  return DynamicLibrary.open(libraryNextToScript.path);
}
// _openOnWindows could be implemented similarly by opening `sqlite3.dll`

```

## Migrating from moor_flutter to moor_ffi

If you're not running into a limitation that forces you to use `moor_ffi`, be aware
that staying on `moor_flutter` is a more stable solution at the moment.

First, adapt your `pubspec.yaml`: You can remove the `moor_flutter` dependency and instead
add both the `moor` and `moor_ffi` dependencies:
```yaml
dependencies:
 moor: ^2.0.0
 moor_ffi: ^0.2.0
 sqflite: ^1.1.7 # Still used to obtain the database location
dev_dependencies:
 moor_generator: ^2.0.0
```

Adapt your imports:

  - In the file where you created a `FlutterQueryExecutor`, replace the `moor_flutter` import
    with `package:moor_ffi/moor_ffi.dart`.
  - In all other files where you might have import `moor_flutter`, just import `package:moor/moor.dart`.
  
Replace the executor. This code:
```dart
FlutterQueryExecutor.inDatabaseFolder(path: 'db.sqlite')
```
can now be written as
```dart
import 'package:sqflite/sqflite.dart' show getDatabasesPath;
import 'package:path/path.dart' as p;

LazyDatabase(() async {
   final dbFolder = await getDatabasesPath();
   final file = File(j.join(dbFolder, 'db.sqlite'));
   return VmDatabase(file);
})
```

Note: If you haven't shipped a version with `moor_flutter` to your users yet, you can drop the dependency
on `sqflite`. Instead, you can use `path_provider` which [works on Desktop](https://github.com/google/flutter-desktop-embedding/tree/master/plugins/flutter_plugins).
Please be aware that `FlutterQueryExecutor.inDatabaseFolder` might yield a different folder than
`path_provider` on Android. This can cause data loss if you've already shipped a version using
`moor_flutter`. In that case, using `getDatabasePath` from sqflite is the suggested solution.

## Used compile options on Android

Note: Android is the only platform where moor_ffi will compile sqlite. The sqlite3 library from the system
is used on all other platforms. The choosen options help reduce binary size by removing features not used by
moor. Important options are marked in bold.

- We use the `-O3` performance option
- __SQLITE_DQS=0__: This will make sqlite not accept double-quoted strings (and instead parse them as identifiers). This matches
  the behavior of moor and compiled queries
- __SQLITE_THREADSAFE=0__: Since the majority of Flutter apps only use one isolate, thread safety is turned off. Note that you
  can still use the [isolate api]({{<relref "../Advanced Features/isolates.md">}}) for background operations. As long as all
  database accesses happen from the same thread, there's no problem.
- SQLITE_DEFAULT_MEMSTATUS=0: The `sqlite3_status()` interfaces are not exposed by moor_ffi, so there's no point of having them.
- SQLITE_MAX_EXPR_DEPTH=0: Disables maximum depth when sqlite parses expressions, which can make the parser faster.
- `SQLITE_OMIT_AUTHORIZATION`, `SQLITE_OMIT_DECLTYPE`, __SQLITE_OMIT_DEPRECATED__, `SQLITE_OMIT_GET_TABLE`, `SQLITE_OMIT_LOAD_EXTENSION`,
  `SQLITE_OMIT_PROGRESS_CALLBACK`, `SQLITE_OMIT_SHARED_CACHE`, `SQLITE_OMIT_TCL_VARIABLE`, `SQLITE_OMIT_TRACE`: Disables features not supported
  by moor.
- `SQLITE_USE_ALLOCA`: Allocate temporary memory on the stack
- `SQLITE_UNTESTABLE`: Remove util functions that are only required to test sqlite3
- `SQLITE_HAVE_ISNAN`: Use the `isnan` function from the system instead of the one shipped with sqlite3.
- `SQLITE_ENABLE_FTS5`: Enable the [fts5](https://www.sqlite.org/fts5.html) engine for full-text search.
- `SQLITE_ENABLE_JSON1`: Enable the [json1](https://www.sqlite.org/json1.html) extension for json support in sql query.

For more details on sqlite compile options, see [their documentation](https://www.sqlite.org/compile.html).