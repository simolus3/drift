import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
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
    return MigrationStrategy(beforeOpen: (details) async {});
  }
}

QueryExecutor _openDatabase() {
  return driftDatabase(
    name: 'encrypted_database',
    native: DriftNativeOptions(
      setup: (db) {
        final result = db.select('pragma cipher');
        if (result.isEmpty) {
          throw UnsupportedError(
            'This database needs to run with sqlite3multipleciphers, but that '
            'library is not available!',
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

      // By default, `driftDatabase` from `package:drift_flutter` stores the
      // database files in `getApplicationDocumentsDirectory()`.
      databaseDirectory: getApplicationSupportDirectory,
    ),
  );
}
