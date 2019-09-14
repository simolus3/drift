# moor_ffi

Moor backend that uses the new `dart:ffi` apis.

## Supported platforms
At the moment, this plugin supports Android natively. However, it's also going to run on all
platforms that expose `sqlite3` as a shared native library (macOS and virtually all Linux
distros).

## Notes

Using `flutter run` or `flutter build` when this library is imported is going to take very long for
the first time. The reason is that we compile sqlite. Subsequent builds should take an acceptable
time execute.