# moor_ffi

Experimental bindings to sqlite by using `dart:ffi`. This library contains utils to make
integration with [moor](https://pub.dev/packages/moor) easier, but it can also be used
as a standalone package.

## Warnings
At the moment, `dart:ffi` is in preview and there will be breaking changes that this
library has to adapt to. This library has been tested on Dart `2.5.0`.

If you're using a development Dart version (this includes Flutter channels that are not
`stable`), this library might not work.

If you just want to use moor, using the [moor_flutter](https://pub.dev/packages/moor_flutter)
package is the better option at the moment.

## Supported platforms
You can make this library work on any platform that let's you obtain a `DynamicLibrary`
from which moor_ffi loads the functions (see below).

Out of the box, this libraries supports all platforms where `sqlite3` is installed:
- iOS: Yes 
- macOS: Yes
- Linux: Available on most distros
- Windows: When the user has installed sqlite (they probably have)
- Android: Yes when used with Flutter

This library works with and without Flutter. 
If you're using Flutter, this library will bundle `sqlite3` in your Android app. This 
requires the Android NDK to be installed (You can get the NDK in the [SDK Manager](https://developer.android.com/studio/intro/update.html#sdk-manager)
of Android Studio). Note that the first `flutter run` is going to take a very long time as
we need to compile sqlite.

### On other platforms
Using this library on platforms that are not supported out of the box is fairly 
straightforward. For instance, if you release your own `sqlite3.so` with your application,
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
Just be sure to first override the behavior and then opening the database. Further,
if you want to use the isolate api, you can only use a static method or top-level
function to open the library.

### Supported datatypes
This library supports `null`, `int`, other `num`s (converted to double),
`String` and `Uint8List` to bind args. Returned columns from select statements
will have the same types.

## Using without moor
```dart
import 'package:moor_ffi/database.dart';

void main() {
  final database = Database.memory();
  // run some database operations. See the example for details
  database.close();
}
```

You can also use an asynchronous API on a background isolate by using `IsolateDb.openFile`
or `IsolateDb.openMemory`, respectively. be aware that the asynchronous API is much slower,
but it moves work out of the UI isolate.

Be sure to __always__ call `Database.close` to avoid memory leaks!

## Migrating from moor_flutter
__Note__: For production apps, please use `moor_flutter` until this package
reaches a stable version.

Add both `moor` and `moor_ffi` to your pubspec, the `moor_flutter` dependency can be dropped.

```yaml
dependencies:
  moor: ^1.7.0
  moor_ffi: ^0.0.1
dev_dependencies:
  moor_generator: ^1.7.0
```

In the file where you created a `FlutterQueryExecutor`, replace the `moor_flutter` import
with both `package:moor/moor.dart` and `package:moor_ffi/moor_ffi.dart`.
In all other project files that use moor apis (e.g. a `Value` class for companions), just import `package:moor/moor.dart`.

Finally, replace usages of `FlutterQueryExecutor` with `VmDatabase`.

Note that, at the moment, there is no counterpart for `FlutterQueryExecutor.inDatabasePath` and that the async API using
a background isolate is not available yet. Both shortcomings with be fixed by the upcoming moor 2.0 release.