---
title: Dart VM (using ffi)
description: Experimental version of moor using `dart:ffi`
---

## Warnings and supported platforms

Please note that `dart:ffi` is in "preview" at the moment and that there will be breaking
changes. Using the `moor_ffi` package on non-stable Dart or Flutter versions can break.
Also, please don't use the package for production apps yet.

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

__Again__: If you're only looking for Android and iOS support, `moor_flutter` is the
right library to use. 

1. Adapt your `pubspec.yaml`: You can remove the `moor_flutter` dependency and instead
   add both the `moor` and `moor_ffi` dependencies:
   ```yaml
   dependencies:
     moor: ^2.0.0
     moor_ffi: ^0.0.1
   dev_dependencies:
     moor_generator: ^2.0.0
   ```
   Note: If you were using `FlutterQueryExecutor.inDatabasesFolder`, you should also depend
   on `path_provider`. For desktop support of that library, see [this readme](https://github.com/google/flutter-desktop-embedding/tree/master/plugins/flutter_plugins).
2. Adapt your imports:
  - In the file where you created a `FlutterQueryExecutor`, replace the `moor_flutter` import
    with `package:moor_ffi/moor_ffi.dart`.
  - In all other files where you might have import `moor_flutter`, just import `package:moor/moor.dart`.
3. Replace the executor. This code:
   ```dart
   FlutterQueryExecutor.inDatabaseFolder(path: 'db.sqlite')
   ```
   can now be written as
   ```dart
   import 'package:path_provider/path_provider.dart';
   import 'package:path/path.dart' as p;

   LazyDatabase(() async {
       final dbFolder = await getApplicationDocumentsDirectory();
       final file = File(j.join(dbFolder.path, 'db.sqlite'));
       return VmDatabase(file);
   })
   ```
   __Important warning__: `FlutterQueryExecutor.inDatabaseFolder` may use a different folder on Android, which
   can cause data loss. This documentation will provide a better migration guide once `moor_ffi` is stable.
   Please create an issue if you need guidance on this soon.