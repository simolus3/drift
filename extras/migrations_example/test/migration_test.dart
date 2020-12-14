import 'package:moor/moor.dart';
import 'package:migrations_example/database.dart';
import 'package:test/test.dart';
import 'package:moor_generator/api/migrations.dart';

// Import the generated schema helper to instantiate databases at old versions.
import 'generated/schema.dart';

void main() {
  SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('upgrade from v1 to v2', () async {
    final schema = await verifier.schemaAt(1);

    // Add some data to the users table, which only has an id column at v1
    schema.rawDatabase.execute('INSERT INTO users (id) VALUES (1);');

    // Run the migration and verify that it adds the name column.
    final db = Database(schema.connection);
    await verifier.migrateAndValidate(db, 2);

    // Make sure the user is still here
    final user = await db.select(db.users).getSingle();
    expect(user.id, 1);
    expect(user.name, 'no name'); // default from the migration

    await db.close();
  });

  test('upgrade from v2 to v3', () async {
    final connection = await verifier.startAt(2);
    final db = Database(connection);

    await verifier.migrateAndValidate(db, 3);
    await db.close();
  });
}
