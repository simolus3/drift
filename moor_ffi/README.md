# moor_ffi

Moor backend that uses the new `dart:ffi` apis. Note that, while we have integration tests
on this package, it depends on the `dart:ffi` apis, which are in "preview" status at the moment.
Thus, this library is not suited for production use.

If you want to use moor on Android or iOS, see the [getting started guide](https://moor.simonbinder.eu/docs/getting-started/)
which recommends to use the [moor_flutter](https://pub.dev/packages/moor_flutter) package.
At the moment, this library is targeted for advanced moor users who want to try out the `ffi`
backend.

## Supported platforms
At the moment, this plugin supports Android natively. However, it's also going to run on all
platforms that expose `sqlite3` as a shared native library (macOS and virtually all Linux
distros, I'm not sure about Windows). Native iOS and macOS support is planned.

## Migrating from moor_flutter
Add both `moor` and `moor_ffi` to your pubspec.

```yaml
dependencies:
  moor: ^2.0.0
  moor_ffi: ^0.0.1
dev_dependencies:
  moor: ^2.0.0
```

In your main database file, replace the `package:moor_flutter/moor_flutter.dart` import with
`package:moor/moor.dart` and `package:moor_ffi/moor_ffi.dart`.
In all other project files that use moor apis (e.g. a `Value` class for companions), just import `package:moor/moor.dart`.

Finally, replace usages of `FlutterQueryExecutor` with `VmDatabase`.

## Notes
After importing this library, the first Flutter build is going to take a very long time. The reason is that we're 
compiling sqlite to bundle it with your app. Subsequent builds should take an acceptable time to execute.
