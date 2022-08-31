import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

// This database is kep simple on purpose, this example only demonstrates how to
// use drift with an encrypted database.
// For advanced drift features, see the other examples in this project.

const _encryptionPassword = 'drift.example.unsafe_password';

class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text()();
}

@DriftDatabase(tables: [Notes])
class MyEncryptedDatabase extends _$MyEncryptedDatabase {
  MyEncryptedDatabase() : super(_openDatabase());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {},
    );
  }
}

QueryExecutor _openDatabase() {
  return LazyDatabase(() async {
    final path = await getApplicationDocumentsDirectory();

    return NativeDatabase(
      File(p.join(path.path, 'app.db.enc')),
      setup: (db) {
        // Check that we're actually running with SQLCipher by quering the
        // cipher_version pragma.
        final result = db.select('pragma cipher_version');
        if (result.isEmpty) {
          throw UnsupportedError(
            'This database needs to run with SQLCipher, but that library is '
            'not available!',
          );
        }

        // Then, apply the key to encrypt the database. Unfortunately, this
        // pragma doesn't seem to support prepared statements so we inline the
        // key.
        final escapedKey = _encryptionPassword.replaceAll("'", "''");
        db.execute("pragma key = '$escapedKey'");

        // Test that the key is correct by selecting from a table
        db.execute('select count(*) from sqlite_master');
      },
    );
  });
}
