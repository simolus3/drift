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
  final token = RootIsolateToken.instance!;
  NativeDatabase.createInBackground(
    myDatabaseFile,
    isolateSetup: () async {
      BackgroundIsolateBinaryMessenger.ensureInitialized(token);
      await setupSqlCipher();
    },
    setup: (rawDb) {
      rawDb.execute("PRAGMA key = 'passphrase';");

      // Recommended option, not enabled by default on SQLCipher
      rawDb.config.doubleQuotedStringLiterals = false;
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

      // Recommended option, not enabled by default on SQLCipher
      rawDb.config.doubleQuotedStringLiterals = false;
    },
  );
  // #enddocregion encrypted2

  // #docregion migration
  final existingDatabasePath = '/path/to/your/database.db';
  final encryptedDatabasePath = '/path/to/your/encrypted.db';
  const yourKey = 'passphrase';

  String escapeString(String source) {
    return source.replaceAll('\'', '\'\'');
  }

  // This database can be passed to the constructor of your database class
  NativeDatabase.createInBackground(
    File(encryptedDatabasePath),
    isolateSetup: () async {
      BackgroundIsolateBinaryMessenger.ensureInitialized(token);
      await setupSqlCipher();

      final existing = File(existingDatabasePath);
      final encrypted = File(encryptedDatabasePath);

      if (await existing.exists() && !await encrypted.exists()) {
        // We have an existing database to migrate.
        final plaintextDb = sqlite3.open(existingDatabasePath)
          ..execute("ATTACH DATABASE '${escapeString(encryptedDatabasePath)}' "
              "AS encrypted KEY '${escapeString(yourKey)}';")
          ..execute("SELECT sqlcipher_export('encrypted');");

        // sqlcipher_export doesn't apply the user_version pragma used by drift
        // to implement migrations. The version of the encrypted database must
        // match the previous state.
        final userVersion =
            plaintextDb.select('PRAGMA user_version;').first.columnAt(0) as int;
        plaintextDb
          ..execute('PRAGMA encrypted.user_version = $userVersion;')
          ..execute('DETACH DATABASE encrypted;')
          ..dispose();

        // This should have created the encrypted database.
        assert(await encrypted.exists());
        await existing.delete();
      }
    },
    setup: (rawDb) {
      assert(_debugCheckHasCipher(rawDb));
      rawDb.execute("PRAGMA key = '${escapeString(yourKey)}';");

      // Recommended option, not enabled by default on SQLCipher
      rawDb.config.doubleQuotedStringLiterals = false;
    },
  );
  // #enddocregion migration
}
