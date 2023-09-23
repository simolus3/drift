import 'package:drift/drift.dart';

extension MigrateToTextDateTimes on GeneratedDatabase {
  // #docregion unix-to-text
  Future<void> migrateFromUnixTimestampsToText(Migrator m) async {
    for (final table in allTables) {
      final dateTimeColumns =
          table.$columns.where((c) => c.type == DriftSqlType.dateTime);

      if (dateTimeColumns.isNotEmpty) {
        // This table has dateTime columns which need to be migrated.
        await m.alterTable(TableMigration(
          table,
          columnTransformer: {
            for (final column in dateTimeColumns)
              // We assume that the column in the database is an int (unix
              // timestamp), use `fromUnixEpoch` to convert it to a date time.
              // Note that the resulting value in the database is in UTC.
              column: DateTimeExpressions.fromUnixEpoch(column.dartCast<int>()),
          },
        ));
      }
    }
  }
  // #enddocregion unix-to-text
}

extension MigrateToTimestamps on GeneratedDatabase {
  // #docregion text-to-unix
  Future<void> migrateFromTextDateTimesToUnixTimestamps(Migrator m) async {
    for (final table in allTables) {
      final dateTimeColumns =
          table.$columns.where((c) => c.type == DriftSqlType.dateTime);

      if (dateTimeColumns.isNotEmpty) {
        // This table has dateTime columns which need to be migrated.
        await m.alterTable(TableMigration(
          table,
          columnTransformer: {
            for (final column in dateTimeColumns)
              // We assume that the column in the database is a string. We want
              // to parse it to a date in SQL and then get the unix timestamp of
              // it.
              // Note that this requires sqlite version 3.38 or above.
              column: FunctionCallExpression('unixepoch', [column]),
          },
        ));
      }
    }
  }
  // #enddocregion text-to-unix

  Future<void> migrateFromTextDateTimesToUnixTimestampsPre338(
      Migrator m) async {
    for (final table in allTables) {
      final dateTimeColumns =
          table.$columns.where((c) => c.type == DriftSqlType.dateTime);

      if (dateTimeColumns.isNotEmpty) {
        await m.alterTable(TableMigration(
          table,
          // #docregion text-to-unix-old
          columnTransformer: {
            for (final column in dateTimeColumns)
              // Use this as an alternative to `unixepoch`:
              column: FunctionCallExpression(
                  'strftime', [const Constant('%s'), column]).cast<int>(),
          },
          // #enddocregion text-to-unix-old
        ));
      }
    }
  }
}
