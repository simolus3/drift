part of 'package:moor_ffi/moor_ffi.dart';

/// Signature responsible for loading the dynamic sqlite3 library that moor will
/// use.
typedef OpenLibrary = DynamicLibrary Function();

/// The [OpenLibrary] function that will be used for the first time the native
/// library is requested. This can be overridden, but won't have an effect after
/// the library has been opened once (which happens when a `VmDatabase` is
/// instantiated).
OpenLibrary moorSqliteOpener = _defaultOpen;

DynamicLibrary _defaultOpen() {
  if (Platform.isLinux || Platform.isAndroid) {
    return DynamicLibrary.open('libsqlite3.so');
  }
  if (Platform.isMacOS) {
    return DynamicLibrary.open('libsqlite3.dylib');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('sqlite3.dll');
  }

  throw UnsupportedError(
      'moor_ffi does not support ${Platform.operatingSystem} yet');
}
