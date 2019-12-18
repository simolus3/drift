## 0.3.0

- Better setup for compiling sqlite3 on Android
  - Compilation options to increase runtime performance, enable `fts5` and `json1`
  - We no longer download sqlite sources on the first run, they now ship with the plugin

## 0.2.0

- Remove the `background` flag from the moor apis provided by this package. Use the moor isolate api
  instead.
- Remove builtin support for background execution from the low-level `Database` api
- Support Dart 2.6, drop support for older versions

## 0.0.1

- Initial release. Contains standalone bindings and a moor implementation.