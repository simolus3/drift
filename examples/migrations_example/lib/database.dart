import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations.dart';

import 'tables.dart';
import 'src/versions.dart';

part 'database.g.dart';

@DriftDatabase(include: {'tables.drift'})
class Database extends _$Database {
  static const latestSchemaVersion = 9;

  @override
  int get schemaVersion => latestSchemaVersion;

  Database(DatabaseConnection connection) : super(connection);

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: _upgrade,
      beforeOpen: (details) async {
        // For Flutter apps, this should be wrapped in an if (kDebugMode) as
        // suggested here: https://drift.simonbinder.eu/docs/advanced-features/migrations/#verifying-a-database-schema-at-runtime
        await validateDatabaseSchema();
      },
    );
  }

  static final _upgrade = stepByStep(
    from1To2: (m, schema) async {
      // Migration from 1 to 2: Add name column in users. Use "no name"
      // as a default value.

      await m.alterTable(
        TableMigration(
          schema.users,
          columnTransformer: {
            schema.users.name: const Constant<String>('no name'),
          },
          newColumns: [schema.users.name],
        ),
      );
    },
    from2To3: (m, schema) async => m.createTable(schema.groups),
    from3To4: (m, schema) async {
      // Migration from 3 to 4: users.name now has a default value
      // No need to transform any data, just re-create the table
      final usersAtV4 = schema.users;

      await m.alterTable(TableMigration(usersAtV4));
    },
    from4To5: (m, schema) async {
      // Just add a new column that was added in version 5;
      await m.addColumn(schema.users, schema.users.nextUser);

      // And create the view on users
      await m.createView(schema.groupCount);
    },
    from5To6: (m, schema) async {
      await m.addColumn(schema.users, schema.users.birthday);
    },
    from6To7: (m, schema) async {
      await m.createTable(schema.notes);
    },
    from7To8: (m, schema) async {
      // Added a unique key to the users table
      await m.alterTable(TableMigration(schema.users));
    },
    from8To9: (m, schema) async {
      // Added a check to the users table
      await m.alterTable(TableMigration(schema.users));
    },
  );
}
