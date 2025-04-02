import 'package:drift/drift.dart';

/// Contains instructions needed to run a complex migration on a table, using
/// the steps described in [Making other kinds of table schema changes](https://www.sqlite.org/lang_altertable.html#otheralter).
///
/// For examples and more details, see [the documentation](https://drift.simonbinder.eu/docs/advanced-features/migrations/#complex-migrations).
class TableMigration {
  /// The table to migrate. It is assumed that this table already exists at the
  /// time the migration is running. If you need to create a new table, use
  /// [Migrator.createTable] instead of the more complex [TableMigration].
  final GeneratedTable<Object, GeneratedTable> affectedTable;

  /// A list of new columns that are known to _not_ exist in the database yet.
  ///
  /// If these columns aren't set through the [columnTransformer], they must
  /// have a default value.
  final List<TableColumn> newColumns;

  /// A map describing how to transform columns of the [affectedTable].
  ///
  /// A key in the map refers to the new column in the table. If you're running
  /// a [TableMigration] to add new columns, those columns doesn't have to exist
  /// in the database yet.
  /// The value associated with a column is the expression to use when
  /// transforming the new table.
  final Map<TableColumn, Expression> columnTransformer;

  /// Creates migration description on the [affectedTable].
  TableMigration(
    this.affectedTable, {
    this.columnTransformer = const {},
    this.newColumns = const [],
  }) {
    // All new columns must either have a transformation or a default value of
    // some kind
    final problematicNewColumns = <String>[];
    for (final column in newColumns) {
      // isRequired returns false if the column has a client default value that
      // would be used for inserts. We can't apply the client default here
      // though, so it doesn't count as a default value.
      final isRequired =
          column.requiredDuringInsert || column.clientDefault != null;
      if (isRequired && !columnTransformer.containsKey(column)) {
        problematicNewColumns.add(column.name);
      }
    }

    if (problematicNewColumns.isNotEmpty) {
      throw ArgumentError(
        "Some of the newColumns don't have a default value and aren't included "
        'in columnTransformer: ${problematicNewColumns.join(', ')}. \n'
        'To add columns, make sure that they have a default value or write an '
        'expression to use in the columnTransformer map.',
      );
    }
  }
}

extension SqliteMigrator on Migrator {
  /// Alter columns of an existing table.
  ///
  /// Since sqlite does not provide a way to alter the type or constraint of an
  /// individual column, one needs to write a fairly complex migration procedure
  /// for this.
  /// [alterTable] will run the [12 step procedure][other alter] recommended by
  /// sqlite.
  ///
  /// The [migration] to run describes the transformation to apply to the table.
  /// The individual fields of the [TableMigration] class contain more
  /// information on the transformations supported at the moment. Drifts's
  /// [documentation][drift docs] also contains more details and examples for
  /// common migrations that can be run with [alterTable].
  ///
  /// When deleting columns from a table, make sure to migrate tables that have
  /// a foreign key constraint on those columns first.
  ///
  /// While this function will re-create affected indexes and triggers, it does
  /// not reliably handle views at the moment.
  ///
  /// [other alter]: https://www.sqlite.org/lang_altertable.html#otheralter
  /// [drift docs]: https://drift.simonbinder.eu/docs/advanced-features/migrations/#complex-migrations
  Future<void> alterTable(TableMigration migration) async {
    final foreignKeysEnabled =
        (await database.customSelect('PRAGMA foreign_keys').getSingle())
            .read<bool>('foreign_keys');
    bool? legacyAlterTable =
        (await database.customSelect('PRAGMA legacy_alter_table').getSingle())
            .read<bool>('legacy_alter_table');

    if (foreignKeysEnabled) {
      await database.customStatement('PRAGMA foreign_keys = OFF;');
    }

    final table = migration.affectedTable;
    final tableName = table.entityName;

    await database.transaction(() async {
      // We will drop the original table later, which will also delete
      // associated triggers, indices and and views. We query sqlite_schema to
      // re-create those later.
      // We use the legacy sqlite_master table since the _schema rename happened
      // in a very recent version (3.33.0)
      final schemaQuery = await database.customSelect(
        'SELECT type, name, sql FROM sqlite_master WHERE tbl_name = ?;',
        variables: [(database.dialect.textType, tableName)],
      ).get();

      final createAffected = <String>[];

      for (final row in schemaQuery) {
        final type = row.read<String>('type');
        final sql = row.readNullable<String>('sql');
        final name = row.read<String>('name');

        if (sql == null) {
          // These indexes are created by sqlite to enforce different kinds of
          // special constraints.
          // They do not have any SQL create statement as they are created
          // automatically by the constraints on the table.
          // They can not be re-created and need to be skipped.
          assert(name.startsWith('sqlite_autoindex'));
          continue;
        }

        switch (type) {
          case 'trigger':
          case 'view':
          case 'index':
            createAffected.add(sql);
            break;
        }
      }

      // Step 4: Create the new table in the desired format
      final temporaryName = 'tmp_for_copy_$tableName';
      final temporaryTable = table.withAlias(temporaryName);
      await createTable(temporaryTable);

      // Step 5: Transfer old content into the new table
      final compiler = database.dialect.createCompiler();
      final expressionsForSelect = <Expression>[];

      compiler.statement.buffer.write('INSERT INTO $temporaryName (');
      var first = true;
      for (final column in table.columns) {
        if (column.constraints.any((e) => e is ColumnGeneratedAs)) continue;

        final transformer = migration.columnTransformer[column];

        if (transformer != null || !migration.newColumns.contains(column)) {
          // New columns without a transformer have a default value, so we don't
          // include them in the column list of the insert.
          // Otherwise, we prefer to use the column transformer if set. If there
          // isn't a transformer, just copy the column from the old table,
          // without any transformation.
          final expression = migration.columnTransformer[column] ?? column;
          expressionsForSelect.add(expression);

          if (!first) compiler.statement.comma();
          compiler.addReference(column.name);
          first = false;
        }
      }

      compiler.statement.buffer.write(') SELECT ');
      first = true;
      for (final expr in expressionsForSelect) {
        if (!first) compiler.statement.comma();
        expr.compileWith(compiler);
        first = false;
      }
      compiler.statement.buffer.write(' FROM ');
      compiler.addReference(tableName);
      compiler.statement.buffer.write(';');
      (await database.currentSession())
          .execute(StatementInfo(compiler.statement));

      // Step 6: Drop the old table
      await database.runStatement(DropStatement('TABLE', tableName));

      // This step is not mentioned in the documentation, but: If we use `ALTER`
      // on an inconsistent schema (and it is inconsistent right now because
      // we've just dropped the original table), we need to enable the legacy
      // option which skips the integrity check.
      // See also: https://sqlite.org/forum/forumpost/0e2390093fbb8fd6
      if (legacyAlterTable == false) {
        try {
          await database.customStatement('pragma legacy_alter_table = 1;');
        } on Object {
          // On some databases like Turso, legacy_alter_table is not writable.
          legacyAlterTable = null;

          // A workaround is to drop all views and to re-create them later.
          // We're not doing this by default to ensure we're not breaking
          // existing users (e.g. if the new table references a view somehow).
          final allViews = await database.customSelect(
            'SELECT name, sql FROM sqlite_master WHERE type = ?;',
            variables: [(database.dialect.textType, 'view')],
          ).get();

          for (final row in allViews) {
            final sql = row.read<String>('sql');
            if (!createAffected.contains(sql)) {
              createAffected.add(sql);
            }

            final name = row.read<String>('name');
            await database.customStatement('DROP VIEW "$name";');
          }
        }
      }

      // Step 7: Rename the new table to the old name
      await database.runStatement(RenameTableStatement(temporaryName, table));

      if (legacyAlterTable == false) {
        await database.customStatement('pragma legacy_alter_table = 0;');
      }

      // Step 8: Re-create associated indexes, triggers and views
      for (final stmt in createAffected) {
        await database.customStatement(stmt);
      }

      // We don't currently check step 9 and 10, step 11 happens implicitly.
    });

    // Finally, re-enable foreign keys if they were enabled originally.
    if (foreignKeysEnabled) {
      await database.customStatement('PRAGMA foreign_keys = ON;');
    }
  }
}
