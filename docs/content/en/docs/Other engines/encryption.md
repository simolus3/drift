---
title: Encryption
description: Use moor on encrypted databases
---

Starting from 1.7, we have a version of moor that can work with encrypted databases by using the
[sqflite_sqlcipher](https://pub.dev/packages/sqflite_sqlcipher) library
by [@davidmartos96](https://github.com/davidmartos96). To use it, you need to
remove the dependency on `moor_flutter` and `moor_ffi` from your `pubspec.yaml` and replace it
with this:
```yaml
dependencies:
  moor: "$latest version"
  encrypted_moor:
   git:
    url: https://github.com/simolus3/moor.git
    path: extras/encryption 
```

Instead of importing `package:moor_flutter/moor_flutter` in your apps, you would then import
both `package:moor/moor.dart` and `package:encrypted_moor/encrypted_moor.dart`.

Finally, you can replace `FlutterQueryExecutor` with an `EncryptedExecutor`.

## Extra setup on Android and iOS

Some extra steps may have to be taken in your project so that SQLCipher works correctly. For example, the ProGuard configuration on Android for apps built for release.

[Read instructions](https://pub.dev/packages/sqflite_sqlcipher) (Usage and installation instructions of the package can be ignored, as that is handled internally by `moor`)

## Encrypted version of `moor/ffi`

You can also use the new `moor/ffi` library with an encrypted executor. To do so, replace your dependency on `sqlite3_flutter_libs`
with `sqlcipher_flutter_libs`:

```yaml
dependencies:
  sqlcipher_flutter_libs:
    git:
      url: https://github.com/simolus3/sqlite3.dart.git
      path: sqlcipher_flutter_libs
```

You can continue to use a `VmDatabase`, but you need to use the `setup` parameter to decrypt the database:

```dart
VmDatabase(
  File(...),
  setup: (rawDb) {
    rawDb.execute("PRAGMA key = 'passphrase';");
  }
);
```