import 'package:drift/drift.dart';

import 'tables.dart';
import 'src/generated/schema_v2.dart' as v2;
import 'src/generated/schema_v4.dart' as v4;

part 'database.g.dart';

@DriftDatabase(include: {'tables.drift'})
class Database extends _$Database {
  @override
  int get schemaVersion => 5;

  Database(DatabaseConnection connection) : super.connect(connection);

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, before, now) async {
        for (var target = before + 1; target <= now; target++) {
          if (target == 2) {
            // Migration from 1 to 2: Add name column in users. Use "no name"
            // as a default value.
            final usersAtV2 = v2.Users(this);

            await m.alterTable(
              TableMigration(
                usersAtV2,
                columnTransformer: {
                  users.name: const Constant<String>('no name'),
                },
                newColumns: [usersAtV2.name],
              ),
            );
          } else if (target == 3) {
            // Migration from 2 to 3: We added the groups table
            await m.createTable(groups);
          } else if (target == 4) {
            // Migration from 3 to 4: users.name now has a default value
            // No need to transform any data, just re-create the table
            final usersAtV4 = v4.Users(this);

            await m.alterTable(TableMigration(usersAtV4));
          } else if (target == 5) {
            // Just add a new column that was added in version 5;
            await m.addColumn(users, users.nextUser);

            // And create the view on users
            await m.createView(groupCount);
          }
        }
      },
    );
  }
}
