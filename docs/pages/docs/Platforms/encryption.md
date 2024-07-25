---
data:
  title: Encryption
  description: Use drift on encrypted databases
  weight: 10
template: layouts/docs/single
aliases:
  - docs/other-engines/encryption/
---

{% assign snippets = 'package:drift_docs/snippets/platforms/encryption.dart.excerpt.json' | readString | json_decode %}

There are two ways to use drift on encrypted databases.
The `encrypted_drift` package is similar to `drift_sqflite` and uses a platform plugin written in
Java.
Alternatively, you can use the ffi-based implementation with the `sqlcipher_flutter_libs` package.

For new apps, we recommend using `sqlcipher_flutter_libs` with a `NativeDatabase`
from drift.
An example of a Flutter app using the new encryption package is available
[here](https://github.com/simolus3/drift/tree/develop/examples/encryption).

## Using `encrypted_drift`

The drift repository provides a version of drift that can work with encrypted databases by using the
[sqflite_sqlcipher](https://pub.dev/packages/sqflite_sqlcipher) library
by [@davidmartos96](https://github.com/davidmartos96). To use it, you need to
remove the dependency on `drift_sqflite` from your `pubspec.yaml` and replace it
with this:

{% assign versions = 'package:drift_docs/versions.json' | readString | json_decode %}

```yaml
dependencies:
  drift: ^{{ versions.drift }}
  encrypted_drift:
   git:
    url: https://github.com/simolus3/drift.git
    path: extras/encryption
```

Instead of importing `package:drift_sqflite/drift_sqflite.dart` (or `package:drift/native.dart`) in your apps, 
you would then import both `package:drift/drift.dart` and `package:encrypted_drift/encrypted_drift.dart`.

Finally, you can replace `SqfliteQueryExecutor` (or a `NativeDatabase`) with an `EncryptedExecutor`.

### Extra setup on Android and iOS

Some extra steps may have to be taken in your project so that SQLCipher works correctly. For example, the ProGuard configuration on Android for apps built for release.

[Read instructions](https://pub.dev/packages/sqflite_sqlcipher) (Usage and installation instructions of the package can be ignored, as that is handled internally by `encrypted_drift`)

## Encrypted version of a `NativeDatabase`

You can also use the new `drift/native` library with an encrypted executor.
This allows you to use an encrypted drift database on more platforms, which is particularly
interesting for Desktop applications.

### Setup

To use `sqlcipher`, add a dependency on `sqlcipher_flutter_libs`:

```yaml
dependencies:
  sqlcipher_flutter_libs: ^0.6.0
```

If you already have a dependency on `sqlite3_flutter_libs`, __drop that dependency__.
`sqlite3_flutter_libs` and `sqlcipher_flutter_libs` are not compatible
as they both provide a (different) set of `sqlite3` native apis.

On Android, you also need to adapt the opening behavior of the `sqlite3` package to use the encrypted library instead
of the regular `libsqlite3.so`:

{% include "blocks/snippet" snippets = snippets name = "setup" %}

When using drift on a background database, you need to call `setupSqlCipher` on the background isolate
as well. With `NativeDatabase.createInBackground`, which are using isolates internally, you can use
the `setupIsolate` callback to do this - the examples on this page use this as well.
Since `applyWorkaroundToOpenSqlCipherOnOldAndroidVersions()` invokes a platform channel, one needs
to install a `BackgroundIsolateBinaryMessenger` on the isolate as well.

On iOS, macOS and Windows, no additional setup is necessary - simply depend on `sqlcipher_flutter_libs`.
For Linux builds, note that OpenSSL is linked statically by default. If you want to compile your app to use
a dynamically-linked distribution of OpenSSL, see [this](https://github.com/simolus3/sqlite3.dart/issues/186#issuecomment-1742110933)
issue comment.

### Using

SQLCipher implements sqlite3's C api, which means that you can continue to use the `sqlite3` package
or `package:drift/native.dart` without changes. They're both fully compatible with `sqlcipher_flutter_libs`.

To actually encrypt a database, you must set an encryption key before using it.
A good place to do that in drift is the `setup` parameter of `NativeDatabase`, which runs before drift
is using the database in any way:

{% include "blocks/snippet" snippets = snippets name = "encrypted1" %}

{% block "blocks/collapsible" title="Disabling double-quoted string literals" %}
In `sqlite3_flutter_libs`, sqlite3 is compiled to only accept single-quoted string literals.
This is a recommended option to avoid confusion - `SELECT "column" FROM tbl` is always a
column reference, `SELECT 'column'` is always a string literal.

SQLCipher does not disable double-quoted string literals at compile-time. For consistency,
it is recommended to manually disable them for databases used with drift.
{% endblock %}

### Important notice

On the native side, `SQLCipher` and `sqlite3` stand in conflict with each other.
If your package depends on both native libraries, the one you will actually get may be undefined on some platforms.
In particular, if you depend on `sqlcipher_flutter_libs` and another package you use depends on say `sqflite`,
you could still be getting the regular `sqlite3` library without support for encryption!

For this reason, it is recommended that you check that the `cipher_version` pragma is available at runtime:

{% include "blocks/snippet" snippets = snippets name = "check_cipher" %}

Next, add an `assert(_debugCheckHasCipher(database))` before using the database. A suitable place is the
`setup` parameter to a `NativeDatabase`:

{% include "blocks/snippet" snippets = snippets name = "encrypted2" %}

If this check reveals that the encrypted variant is not available, please see [the documentation here](https://github.com/simolus3/sqlite3.dart/tree/master/sqlcipher_flutter_libs#incompatibilities-with-sqlite3-on-ios-and-macos) for advice.
