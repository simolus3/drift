Drift version that uses the [sqflite_sqlcipher](https://github.com/davidmartos96/sqflite_sqlcipher) package instead of sqflite.

## Using this
For general notes on using drift, see [this guide](https://drift.simonbinder.eu/setup/).

Instead of using `drift_flutter`, use this:

```yaml
dependencies:
  drift: ^2.26.0
  encrypted_drift:
   git:
    url: https://github.com/simolus3/drift.git
    path: extras/encryption
```

Instead of importing `package:drift_sqflite/drift_sqflite.dart` (or `package:drift/native.dart`) in your apps, you would then import both `package:drift/drift.dart` and `package:encrypted_drift/encrypted_drift.dart`.

Finally, you can replace `SqfliteQueryExecutor` (or a `NativeDatabase`) with an `EncryptedExecutor`.
