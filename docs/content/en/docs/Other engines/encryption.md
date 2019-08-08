---
title: Encryption
description: Use moor on encrypted databases
---

{{% alert title="Security notice" color="warning" %}}
> This feature uses an external library for all the encryption work. Importing
that library as described here would always pull the latest version from git
when running `pub upgrade`. If you want to be sure that you're using a safe version
that you can trust, consider pulling `sqflite_sqlcipher` and `encrypted_moor` once
and then include your local version via a path in the pubspec.
{{% /alert %}}

Starting from 1.7, we have a version of moor that can work with encrypted databases by using the
[sqflite_sqlcipher](https://github.com/davidmartos96/sqflite_sqlcipher) library
by [@davidmartos96](https://github.com/davidmartos96). To use it, you need to
remove the dependency on `moor_flutter` from your `pubspec.yaml` and replace it
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