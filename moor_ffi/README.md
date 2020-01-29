# moor_ffi

Dart bindings to sqlite by using `dart:ffi`. This library contains utils to make
integration with [moor](https://pub.dev/packages/moor) easier, but it can also be used
as a standalone package. It also doesn't depend on Flutter, so it can be used on Dart VM
applications as well.

## Supported platforms
You can make this library work on any platform that lets you obtain a `DynamicLibrary`
in which sqlite's symbols are available (see below).

Out of the box, this library supports all platforms where `sqlite3` is installed:
- iOS: Yes 
- macOS: Yes
- Linux: Available on most distros
- Windows: Additional setup is required
- Android: Yes when used with Flutter, this library includes the necessary native libraries on Android

### On other platforms
Using this library on platforms that are not supported out of the box is fairly 
straightforward. For instance, if you release your own `sqlite3.so` next to your application,
you could use
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
```
Just be sure to first override the behavior and then open the database. Further,
if you want to use the isolate api, you can only use a static method or a top-level
function to open the library. For Windows, a similar setup with a `sqlite3.dll` library
should work.

### Supported datatypes
This library supports `null`, `int`, `double`, `String` and `Uint8List` to bind args.
Returned columns from select statements will have the same types.

## Using without moor
```dart
import 'package:moor_ffi/database.dart';

void main() {
  final database = Database.memory();
  // run some database operations. See the example for details
  database.close();
}
```

Be sure to __always__ call `Database.close` to avoid memory leaks!

## Using with moor
If you're migrating an existing project using `moor_flutter`, see the 
[documentation](https://moor.simonbinder.eu/docs/other-engines/vm/#migrating-from-moor-flutter-to-moor-ffi).

Add both `moor` and `moor_ffi` to your pubspec:
```yaml
dependencies:
  moor: ^2.0.0
  moor_ffi: ^0.2.0
dev_dependencies:
  moor_generator: ^2.0.0
```

You can then use a `VmDatabase` as an executor:
```dart
@UseMoor(...)
class MyDatabase extends _$MyDatabase {

  MyDatabase(): super(VmDatabase(File('app.db')));
}
```
If you need to find an appropriate directory for the database file, you can use the `LazyDatabase` wrapper
from moor. It can be used to create the inner `VmDatabase` asynchronously:
```dart
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// use this instead of VmDatabase(...)
LazyDatabase(() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = File(p.join(dbFolder.path, 'app.db'));
  return VmDatabase(file);
});
```