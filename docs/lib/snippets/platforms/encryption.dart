import 'dart:io';
import 'package:drift/native.dart';
import 'package:drift_docs/snippets/isolates.dart';
import 'package:sqlite3/sqlite3.dart';

// #docregion setup
import 'package:sqlite3/open.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

// call this method before using drift
Future<void> setupSqlCipher() async {
  await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
  open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
}
// #enddocregion setup

// #docregion check_cipher
bool _debugCheckHasCipher(Database database) {
  return database.select('PRAGMA cipher_version;').isNotEmpty;
}
// #enddocregion check_cipher

void databases() {
  final myDatabaseFile = File('/dev/null');

  // #docregion encrypted1
  final token = RootIsolateToken.instance;
  NativeDatabase.createInBackground(
    myDatabaseFile,
    isolateSetup: () async {
      BackgroundIsolateBinaryMessenger.ensureInitialized(token);
      await setupSqlCipher();
    },
    setup: (rawDb) {
      rawDb.execute("PRAGMA key = 'passphrase';");
    },
  );
  // #enddocregion encrypted1

  // #docregion encrypted2
  NativeDatabase.createInBackground(
    myDatabaseFile,
    isolateSetup: () async {
      BackgroundIsolateBinaryMessenger.ensureInitialized(token);
      await setupSqlCipher();
    },
    setup: (rawDb) {
      assert(_debugCheckHasCipher(rawDb));
      rawDb.execute("PRAGMA key = 'passphrase';");
    },
  );
  // #enddocregion encrypted2
}
