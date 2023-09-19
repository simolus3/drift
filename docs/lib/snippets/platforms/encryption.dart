import 'dart:io';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';

// #docregion setup
import 'dart:ffi';
import 'package:sqlite3/open.dart';

// call this method before using drift
void setupSqlCipher() {
  open.overrideFor(
      OperatingSystem.android, () => DynamicLibrary.open('libsqlcipher.so'));
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
  NativeDatabase.createInBackground(
    myDatabaseFile,
    isolateSetup: setupSqlCipher,
    setup: (rawDb) {
      rawDb.execute("PRAGMA key = 'passphrase';");
    },
  );
  // #enddocregion encrypted1

  // #docregion encrypted2
  NativeDatabase.createInBackground(
    myDatabaseFile,
    isolateSetup: setupSqlCipher,
    setup: (rawDb) {
      assert(_debugCheckHasCipher(rawDb));
      rawDb.execute("PRAGMA key = 'passphrase';");
    },
  );
  // #enddocregion encrypted2
}
