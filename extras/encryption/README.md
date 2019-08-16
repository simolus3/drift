Moor version that uses the
[sqflite_sqlcipher](https://github.com/davidmartos96/sqflite_sqlcipher) instead of
sqflite.

## Using this
For general notes on using moor, see [this guide](https://moor.simonbinder.eu/getting-started/).

Instead of using `moor_flutter`, use this:
```yaml
dependencies:
  moor: "$latest version"
  encrypted_moor:
   git:
    url: https://github.com/simolus3/moor.git
    path: extras/encryption 
```

To use this, you can stop depending on `moor_flutter`. Then, instead of using 
a `FlutterQueryExecutor`, import `package:moor/moor.dart` and `package:encrypted_moor/encrypted_moor.dart`.

You can then replace the `FlutterQueryExecutor` with an `EncryptedExecutor`.
