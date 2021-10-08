//@dart=2.9
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations.dart';
import 'package:test/test.dart';

void main() {
  final verifier = SchemaVerifier(_TestHelper());

  group('startAt', () {
    test('starts at the requested version', () async {
      final db = (await verifier.startAt(17)).executor;
      await db.ensureOpen(_DelegatedUser(17, (_, details) async {
        expect(details.wasCreated, isFalse, reason: 'was opened before');
        expect(details.hadUpgrade, isFalse, reason: 'no upgrade expected');
      }));
    });
  });

  group('migrateAndValidate', () {
    test('invokes a migration', () async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      OpeningDetails capturedDetails;

      final connection = await verifier.startAt(3);
      final db = _TestDatabase(connection.executor, 7)
        ..migration = MigrationStrategy(onUpgrade: (m, from, to) async {
          capturedDetails = OpeningDetails(from, to);
        });

      await verifier.migrateAndValidate(db, 4);
      expect(capturedDetails.versionBefore, 3);
      expect(capturedDetails.versionNow, 4);

      driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
    });
  });
}

class _TestHelper implements SchemaInstantiationHelper {
  @override
  GeneratedDatabase databaseForVersion(QueryExecutor db, int version) {
    return _TestDatabase(db, version);
  }
}

class _TestDatabase extends GeneratedDatabase {
  @override
  final int schemaVersion;

  @override
  MigrationStrategy migration = MigrationStrategy();

  _TestDatabase(QueryExecutor executor, this.schemaVersion)
      : super(const SqlTypeSystem.withDefaults(), executor);

  @override
  Iterable<TableInfo<Table, DataClass>> get allTables {
    return const Iterable.empty();
  }
}

class _DelegatedUser extends QueryExecutorUser {
  @override
  final int schemaVersion;
  final Future<void> Function(QueryExecutor, OpeningDetails) _beforeOpen;

  _DelegatedUser(this.schemaVersion, this._beforeOpen);

  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) {
    return _beforeOpen(executor, details);
  }
}
