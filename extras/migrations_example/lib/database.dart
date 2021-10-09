import 'package:drift/drift.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(include: {'tables.drift'})
class Database extends _$Database {
  @override
  int get schemaVersion => 4;

  Database(DatabaseConnection connection) : super.connect(connection);

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, before, now) async {
        for (var target = before + 1; target <= now; target++) {
          if (target == 2) {
            // Migration from 1 to 2: Add name column in users. Use "no name"
            // as a default value.
            await m.alterTable(
              TableMigration(
                users,
                columnTransformer: {
                  users.name: const Constant<String>('no name'),
                },
                newColumns: [users.name],
              ),
            );
          } else if (target == 3) {
            // Migration from 2 to 3: We added the groups table
            await m.createTable(groups);
          } else if (target == 4) {
            // Migration from 3 to 4: users.name now has a default value
            // No need to transform any data, just re-create the table
            await m.alterTable(TableMigration(users));
          }
        }
      },
    );
  }
}
