## 0.2.6

- Add `initializeDatabase` parameter to `DriftWebOptions` to enable loading initial database.

## 0.2.5

- Fix `DriftWebOptions.onResult` not being called.
- Add `setup` parameter to `DriftNativeOptions` to customize native database connections.

## 0.2.4

- Allow providing a custom temporary directory.
- Allow providing a custom database directory, making it easier to swap out the
  default `getApplicationDocumentsDirectory()`.

## 0.2.3

- Fix compiling to WebAssembly with Dart 3.6.0.

## 0.2.2

- Fix infinite loop in isolate server lookups when using `shareAcrossIsolates`
  across hot restarts.

## 0.2.1

- Enable serialization between background isolates where necessary.

## 0.2.0

- Add `DriftNativeOptions` with `shareAcrossIsolates` option that will give
  multiple isolates access to the same drift database without having to manually
  set up ports.

## 0.1.0

- Initial version.
