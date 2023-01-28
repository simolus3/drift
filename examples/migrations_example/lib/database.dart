import 'package:drift/drift.dart';

import 'tables.dart';
import 'src/generated/schema_v2.dart' as v2;
import 'src/generated/schema_v4.dart' as v4;
import 'src/generated/schema_v8.dart' as v8;

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
      onUpgrade: (m, before, now) async {
        for (var target = before + 1; target <= now; target++) {
          switch (target) {
            case 2:
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
              break;
            case 3:
              // Migration from 2 to 3: We added the groups table
              await m.createTable(groups);
              break;
            case 4:
              // Migration from 3 to 4: users.name now has a default value
              // No need to transform any data, just re-create the table
              final usersAtV4 = v4.Users(this);

              await m.alterTable(TableMigration(usersAtV4));
              break;
            case 5:
              // Just add a new column that was added in version 5;
              await m.addColumn(users, users.nextUser);

              // And create the view on users
              await m.createView(groupCount);
              break;
            case 6:
              await m.addColumn(users, users.birthday);
              break;
            case 7:
              await m.createTable(notes);
              break;
            case 8:
              // Added a unique key to the users table
              await m.alterTable(TableMigration(v8.Users(this)));
              break;
            case 9:
              // Added a check to the users table
              await m.alterTable(TableMigration(users));
              break;
          }
        }
      },
    );
  }
}
