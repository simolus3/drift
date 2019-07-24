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

Then, instead using a `FlutterQueryExecutor`, 
`import 'package:encrypted_moor/encrypted_moor.dart'` and use the `EncryptedExecutor`.