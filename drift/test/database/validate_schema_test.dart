@TestOn('vm')
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations.dart';
import 'package:test/test.dart';

import '../generated/custom_tables.dart';
import '../test_utils/test_utils.dart';

void main() {
  test('finds mismatch for datetime format', () async {
    final db = CustomTablesDb.connect(testInMemoryDatabase())
      ..options = const DriftDatabaseOptions(storeDateTimeAsText: false);
    await db.customSelect('SELECT 1').get(); // Open db, setup tables

    db.options = const DriftDatabaseOptions(storeDateTimeAsText: true);
    // Validation should fail now because datetimes are in the wrong format.

    await expectLater(
      db.validateDatabaseSchema(),
      throwsA(isA<SchemaMismatch>().having((e) => e.toString(), 'toString()',
          contains('Expected TEXT, got INTEGER'))),
    );
  });
}
