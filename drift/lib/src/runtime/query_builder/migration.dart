part of 'query_builder.dart';

/// Signature of a function that will be invoked when a database is created.
typedef OnCreate = Future<void> Function(Migrator m);

/// Signature of a function that will be invoked when a database is upgraded
/// or downgraded.
/// In version upgrades: from < to
/// In version downgrades: from > to
typedef OnUpgrade = Future<void> Function(Migrator m, int from, int to);

/// Signature of a function that's called before a database is marked opened by
/// drift, but after migrations took place. This is a suitable callback to to
/// populate initial data or issue `PRAGMA` statements that you want to use.
typedef OnBeforeOpen = Future<void> Function(OpeningDetails details);

Future<void> _defaultOnCreate(Migrator m) => m.createAll();

Future<void> _defaultOnUpdate(Migrator m, int from, int to) async =>
    throw Exception("You've bumped the schema version for your drift database "
        "but didn't provide a strategy for schema updates. Please do that by "
        'adapting the migrations getter in your database class.');

/// Handles database migrations by delegating work to [OnCreate] and [OnUpgrade]
/// methods.
class MigrationStrategy {
  /// Executes when the database is opened for the first time.
  final OnCreate onCreate;

  /// Executes when the database has been opened previously, but the last access
  /// happened at a different [GeneratedDatabase.schemaVersion].
  /// Schema version upgrades and downgrades will both be run here.
  final OnUpgrade onUpgrade;

  /// Executes after the database is ready to be used (ie. it has been opened
  /// and all migrations ran), but before any other queries will be sent. This
  /// makes it a suitable place to populate data after the database has been
  /// created or set sqlite `PRAGMAS` that you need.
  final OnBeforeOpen? beforeOpen;

  /// Construct a migration strategy from the provided [onCreate] and
  /// [onUpgrade] methods.
  MigrationStrategy({
    this.onCreate = _defaultOnCreate,
    this.onUpgrade = _defaultOnUpdate,
    this.beforeOpen,
  });
}

/// Runs migrations declared by a [MigrationStrategy].
class Migrator {
  final GeneratedDatabase _db;
  final VersionedSchema? _fixedVersion;

  /// Used internally by drift when opening the database.
  Migrator(this._db, [this._fixedVersion]);

  Iterable<DatabaseSchemaEntity> get _allSchemaEntities {
    return switch (_fixedVersion) {
      null => _db.allSchemaEntities,
      var fixed => fixed.entities,
    };
  }

  /// Creates all tables specified for the database, if they don't exist
  @Deprecated('Use createAll() instead')
  Future<void> createAllTables() async {
    for (final table in _allSchemaEntities.whereType<TableInfo>()) {
      await createTable(table);
    }
  }

  /// Creates all tables, triggers, views, indexes and everything else defined
  /// in the database, if they don't exist.
  Future<void> createAll() async {
    for (final entity in _allSchemaEntities) {
      await create(entity);
    }
  }

  /// Creates the given [entity], which can be a table, a view, a trigger, an
  /// index or an [OnCreateQuery].
  Future<void> create(DatabaseSchemaEntity entity) async {
    if (entity is TableInfo) {
      await createTable(entity);
    } else if (entity is Trigger) {
      await createTrigger(entity);
    } else if (entity is Index) {
      await createIndex(entity);
    } else if (entity is OnCreateQuery) {
      await _issueQueryByDialect(entity.sqlByDialect);
    } else if (entity is ViewInfo) {
      await createView(entity);
    } else {
      throw ArgumentError('Unknown entity type: $entity');
    }
  }

  /// Drops and re-creates all views known to the database.
  ///
  /// Calling this may be useful in migrations that could potentially affect
  /// views. This includes changes to a view itself, but changes to tables that
  /// a view reads from may also warrant re-creating the view to make sure it's
  /// still valid.
  Future<void> recreateAllViews() async {
    for (final entity in _allSchemaEntities) {
      if (entity is ViewInfo) {
        await drop(entity);
        await createView(entity);
      }
    }
  }

  GenerationContext _createContext({bool supportsVariables = false}) {
    return GenerationContext.fromDb(_db, supportsVariables: supportsVariables);
  }

  /// Creates the given table if it doesn't exist
  Future<void> createTable(TableInfo table) async {
    final context = _createContext();

    if (table is VirtualTableInfo) {
      _writeCreateVirtual(table, context);
    } else {
      _writeCreateTable(table, context);
    }

    return _issueCustomQuery(context.sql, context.boundVariables);
  }

  /// Alter columns of an existing tabe.
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
    final dialect = _db.executor.dialect;
    bool foreignKeysEnabled;

    if (dialect == SqlDialect.sqlite) {
      foreignKeysEnabled =
          (await _db.customSelect('PRAGMA foreign_keys').getSingle())
              .read<bool>('foreign_keys');
    } else if (dialect == SqlDialect.mariadb) {
      foreignKeysEnabled = (await _db
              .customSelect(
                  'SELECT @@SESSION.foreign_key_checks as foreign_keys')
              .getSingle())
          .read<bool>('foreign_keys');
    } else {
      foreignKeysEnabled =
          (await _db.customSelect('PRAGMA foreign_keys').getSingle())
              .read<bool>('foreign_keys');
    }

    final legacyAlterTable = dialect == SqlDialect.mariadb
        ? null
        : (await _db.customSelect('PRAGMA legacy_alter_table').getSingle())
            .read<bool>('legacy_alter_table');

    if (foreignKeysEnabled) {
      if (dialect == SqlDialect.sqlite) {
        await _db.customStatement('PRAGMA foreign_keys = OFF;');
      } else if (dialect == SqlDialect.mariadb) {
        await _db.customStatement('SET FOREIGN_KEY_CHECKS = OFF;');
      } else {
        await _db.customStatement('PRAGMA foreign_keys = OFF;');
      }
    }

    final table = migration.affectedTable;
    final tableName = table.actualTableName;

    await _db.transaction(() async {
      // We will drop the original table later, which will also delete
      // associated triggers, indices and and views. We query sqlite_schema to
      // re-create those later.
      // We use the legacy sqlite_master table since the _schema rename happened
      // in a very recent version (3.33.0)
      final schemaQuery = await _db.customSelect(
        'SELECT type, name, sql FROM sqlite_master WHERE tbl_name = ?;',
        variables: [Variable<String>(tableName)],
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
      final temporaryTable = table.createAlias(temporaryName);
      await createTable(temporaryTable);

      // Step 5: Transfer old content into the new table
      final context = _createContext(supportsVariables: true);
      final expressionsForSelect = <Expression>[];

      context.buffer.write('INSERT INTO $temporaryName (');
      var first = true;
      for (final column in table.$columns) {
        if (column.generatedAs != null) continue;

        final transformer = migration.columnTransformer[column];

        if (transformer != null || !migration.newColumns.contains(column)) {
          // New columns without a transformer have a default value, so we don't
          // include them in the column list of the insert.
          // Otherwise, we prefer to use the column transformer if set. If there
          // isn't a transformer, just copy the column from the old table,
          // without any transformation.
          final expression = migration.columnTransformer[column] ?? column;
          expressionsForSelect.add(expression);

          if (!first) context.buffer.write(', ');
          context.buffer.write(column.escapedName);
          first = false;
        }
      }

      context.buffer.write(') SELECT ');
      first = true;
      for (final expr in expressionsForSelect) {
        if (!first) context.buffer.write(', ');
        expr.writeInto(context);
        first = false;
      }
      context.buffer.write(' FROM ${context.identifier(tableName)};');
      await _issueCustomQuery(context.sql, context.boundVariables);

      // Step 6: Drop the old table
      await _issueCustomQuery('DROP TABLE ${context.identifier(tableName)}');

      // This step is not mentioned in the documentation, but: If we use `ALTER`
      // on an inconsistent schema (and it is inconsistent right now because
      // we've just dropped the original table), we need to enable the legacy
      // option which skips the integrity check.
      // See also: https://sqlite.org/forum/forumpost/0e2390093fbb8fd6
      if (legacyAlterTable == false) {
        await _issueCustomQuery('pragma legacy_alter_table = 1;');
      }

      // Step 7: Rename the new table to the old name
      if (dialect == SqlDialect.sqlite) {
        await _issueCustomQuery(
            'ALTER TABLE ${context.identifier(temporaryName)} '
            'RENAME TO ${context.identifier(tableName)}');
      } else if (dialect == SqlDialect.mariadb) {
        await _issueCustomQuery(
            'RENAME TABLE ${context.identifier(temporaryName)} '
            'TO ${context.identifier(tableName)}');
      } else {
        await _issueCustomQuery(
            'ALTER TABLE ${context.identifier(temporaryName)} '
            'RENAME TO ${context.identifier(tableName)}');
      }

      if (legacyAlterTable == false) {
        await _issueCustomQuery('pragma legacy_alter_table = 0;');
      }

      // Step 8: Re-create associated indexes, triggers and views
      for (final stmt in createAffected) {
        await _issueCustomQuery(stmt);
      }

      // We don't currently check step 9 and 10, step 11 happens implicitly.
    });

    // Finally, re-enable foreign keys if they were enabled originally.
    if (foreignKeysEnabled) {
      if (dialect == SqlDialect.sqlite) {
        await _db.customStatement('PRAGMA foreign_keys = ON;');
      } else if (dialect == SqlDialect.mariadb) {
        await _db.customStatement('SET FOREIGN_KEY_CHECKS = ON;');
      } else {
        await _db.customStatement('PRAGMA foreign_keys = ON;');
      }
    }
  }

  void _writeCreateTable(TableInfo table, GenerationContext context) {
    context.buffer.write('CREATE TABLE IF NOT EXISTS '
        '${context.identifier(table.aliasedName)} (');

    var hasAutoIncrement = false;
    for (var i = 0; i < table.$columns.length; i++) {
      final column = table.$columns[i];
      if (column.hasAutoIncrement) {
        hasAutoIncrement = true;
      }

      column.writeColumnDefinition(context);

      if (i < table.$columns.length - 1) context.buffer.write(', ');
    }

    final dslTable = table.asDslTable;

    if (!dslTable.dontWriteConstraints) {
      final hasPrimaryKey = table.$primaryKey.isNotEmpty;

      // we're in a bit of a hacky situation where we don't write the primary
      // as table constraint if it has already been written on a primary key
      // column, even though that column appears in table.$primaryKey because we
      // need to know all primary keys for the update(table).replace(row) API
      if (hasPrimaryKey && !hasAutoIncrement) {
        context.buffer.write(', PRIMARY KEY (');
        final pkList = table.$primaryKey.toList(growable: false);
        for (var i = 0; i < pkList.length; i++) {
          final column = pkList[i];

          context.buffer.write(column.escapedName);

          if (i != pkList.length - 1) context.buffer.write(', ');
        }
        context.buffer.write(')');
      }

      if (table.uniqueKeys.isNotEmpty) {
        for (final key in table.uniqueKeys) {
          context.buffer.write(', UNIQUE (');
          final uqList = key.toList(growable: false);
          for (var i = 0; i < uqList.length; i++) {
            final column = uqList[i];

            context.buffer.write(column.escapedName);

            if (i != uqList.length - 1) context.buffer.write(', ');
          }
          context.buffer.write(')');
        }
      }
    }

    final constraints = dslTable.customConstraints;

    for (var i = 0; i < constraints.length; i++) {
      context.buffer
        ..write(', ')
        ..write(constraints[i]);
    }

    context.buffer.write(')');

    // == true because of nullability
    if (dslTable.withoutRowId) {
      context.buffer.write(' WITHOUT ROWID');
    }
    if (dslTable.isStrict) {
      context.buffer.write(' STRICT');
    }

    context.buffer.write(';');
  }

  void _writeCreateVirtual(VirtualTableInfo table, GenerationContext context) {
    context.buffer
      ..write('CREATE VIRTUAL TABLE IF NOT EXISTS ')
      ..write(context.identifier(table.aliasedName))
      ..write(' USING ')
      ..write(table.moduleAndArgs)
      ..write(';');
  }

  /// Executes the `CREATE TRIGGER` statement that created the [trigger].
  Future<void> createTrigger(Trigger trigger) {
    return _issueQueryByDialect(trigger.createStatementsByDialect);
  }

  /// Executes a `CREATE INDEX` statement to create the [index].
  Future<void> createIndex(Index index) {
    return _issueQueryByDialect(index.createStatementsByDialect);
  }

  /// Executes a `CREATE VIEW` statement to create the [view].
  Future<void> createView(ViewInfo view) async {
    final stmts = view.createViewStatements;
    if (stmts != null) {
      await _issueQueryByDialect(stmts);
    } else if (view.query != null) {
      final context = GenerationContext.fromDb(_db, supportsVariables: false);
      final columnNames = view.$columns.map((e) => e.escapedName).join(', ');

      context.generatingForView = view.entityName;
      context.buffer.write('CREATE VIEW IF NOT EXISTS '
          '${context.identifier(view.entityName)} ($columnNames) AS ');
      view.query!.writeInto(context);
      await _issueCustomQuery(context.sql, const []);
    }
  }

  /// Drops a table, trigger or index.
  Future<void> drop(DatabaseSchemaEntity entity) async {
    final context = _createContext();
    final escapedName = context.identifier(entity.entityName);

    String kind;

    if (entity is TableInfo) {
      kind = 'TABLE';
    } else if (entity is Trigger) {
      kind = 'TRIGGER';
    } else if (entity is Index) {
      kind = 'INDEX';
    } else if (entity is ViewInfo) {
      kind = 'VIEW';
    } else {
      // Entity that can't be dropped.
      return;
    }

    await _issueCustomQuery('DROP $kind IF EXISTS $escapedName;');
  }

  /// Deletes the table with the given name. Note that this function does not
  /// escape the [name] parameter.
  Future<void> deleteTable(String name) async {
    final context = _createContext();
    return _issueCustomQuery(
        'DROP TABLE IF EXISTS ${context.identifier(name)};');
  }

  /// Adds the given column to the specified table.
  Future<void> addColumn(TableInfo table, GeneratedColumn column) async {
    final context = _createContext();

    context.buffer.write(
        'ALTER TABLE ${context.identifier(table.aliasedName)} ADD COLUMN ');
    column.writeColumnDefinition(context);
    context.buffer.write(';');

    return _issueCustomQuery(context.sql);
  }

  /// Changes the name of a column in a [table].
  ///
  /// After renaming a column in a Dart table or a drift file and re-running the
  /// generator, you can use [renameColumn] in a migration step to rename the
  /// column for existing databases.
  ///
  /// The [table] argument must be set to the table enclosing the changed
  /// column. The [oldName] must be set to the old name of the [column] in SQL.
  /// For Dart tables, note that drift will transform `camelCase` column names
  /// in Dart to `snake_case` column names in SQL.
  ///
  /// __Important compatibility information__: [renameColumn] uses an
  /// `ALTER TABLE RENAME COLUMN` internally. Support for that syntax was added
  /// in sqlite version 3.25.0, released on 2018-09-15. When you're using
  /// Flutter and depend on `sqlite3_flutter_libs`, you're guaranteed to have
  /// that version. Otherwise, please ensure that you only use [renameColumn] if
  /// you know you'll run on sqlite 3.20.0 or later. In MariaDB support for that
  /// same syntax was added in MariaDB version 10.5.2, released on 2020-03-26.
  Future<void> renameColumn(
      TableInfo table, String oldName, GeneratedColumn column) async {
    final context = _createContext();
    context.buffer
      ..write('ALTER TABLE ${context.identifier(table.aliasedName)} ')
      ..write('RENAME COLUMN ${context.identifier(oldName)} ')
      ..write('TO ${column.escapedName};');

    return _issueCustomQuery(context.sql);
  }

  /// Changes the [table] name from [oldName] to the current
  /// [TableInfo.actualTableName].
  ///
  /// After renaming a table in drift or Dart and re-running the generator, you
  /// can use [renameTable] in a migration step to rename the table in existing
  /// databases.
  Future<void> renameTable(TableInfo table, String oldName) async {
    final context = _createContext();
    final dialect = context.dialect;
    if (dialect == SqlDialect.sqlite) {
      context.buffer.write('ALTER TABLE ${context.identifier(oldName)} '
          'RENAME TO ${context.identifier(table.actualTableName)};');
    } else if (dialect == SqlDialect.mariadb) {
      context.buffer.write('RENAME TABLE ${context.identifier(oldName)} '
          'TO ${context.identifier(table.actualTableName)};');
    } else {
      context.buffer.write('ALTER TABLE ${context.identifier(oldName)} '
          'RENAME TO ${context.identifier(table.actualTableName)};');
    }
    return _issueCustomQuery(context.sql);
  }

  /// Executes the custom query.
  @Deprecated('Use customStatement in the database class')
  Future<void> issueCustomQuery(String sql, [List<dynamic>? args]) {
    return _issueCustomQuery(sql, args);
  }

  Future<void> _issueQueryByDialect(Map<SqlDialect, String> sql) {
    final context = _createContext();
    return _issueCustomQuery(context.pickForDialect(sql), const []);
  }

  Future<void> _issueCustomQuery(String sql, [List<dynamic>? args]) {
    return _db.customStatement(sql, args);
  }

  /// A helper used by drift internally to implement the [step-by-step](https://drift.simonbinder.eu/docs/advanced-features/migrations/#step-by-step)
  /// migration feature.
  ///
  /// This method implements an [OnUpgrade] callback by repeatedly invoking
  /// [step] with the current version, assuming that [step] will perform an
  /// upgrade from that version to the version returned by the callback.
  @experimental
  static OnUpgrade stepByStepHelper({
    required Future<int> Function(
      int currentVersion,
      GeneratedDatabase database,
    ) step,
  }) {
    return (m, from, to) async {
      final database = m._db;

      for (var target = from; target < to;) {
        final newVersion = await step(target, database);
        assert(newVersion > target);

        target = newVersion;
      }
    };
  }
}

/// Provides information about whether migrations ran before opening the
/// database.
class OpeningDetails {
  /// The schema version before the database has been opened, or `null` if the
  /// database has just been created.
  final int? versionBefore;

  /// The schema version after running migrations.
  final int versionNow;

  /// Whether the database has been created during this session.
  bool get wasCreated => versionBefore == null;

  /// Whether a schema upgrade was performed while opening the database.
  bool get hadUpgrade => !wasCreated && versionBefore != versionNow;

  /// Used internally by drift when opening a database.
  const OpeningDetails(this.versionBefore, this.versionNow)
      // Should use null instead of 0 for consistency
      : assert(versionBefore != 0);
}

/// Extension providing the [destructiveFallback] strategy.
extension DestructiveMigrationExtension on GeneratedDatabase {
  /// Provides a destructive [MigrationStrategy] that will delete and then
  /// re-create all tables, triggers and indices.
  ///
  /// To use this behavior, override the `migration` getter in your database:
  ///
  /// ```dart
  /// @DriftDatabase(...)
  /// class MyDatabase extends _$MyDatabase {
  ///   @override
  ///   MigrationStrategy get migration => destructiveFallback;
  /// }
  /// ```
  MigrationStrategy get destructiveFallback {
    return MigrationStrategy(
      onCreate: _defaultOnCreate,
      onUpgrade: (m, from, to) async {
        // allSchemaEntities are sorted topologically references between them.
        // Reverse order for deletion in order to not break anything.
        final reversedEntities = m._db.allSchemaEntities.toList().reversed;

        for (final entity in reversedEntities) {
          await m.drop(entity);
        }

        // Re-create them now
        await m.createAll();
      },
    );
  }
}

/// Contains instructions needed to run a complex migration on a table, using
/// the steps described in [Making other kinds of table schema changes](https://www.sqlite.org/lang_altertable.html#otheralter).
///
/// For examples and more details, see [the documentation](https://drift.simonbinder.eu/docs/advanced-features/migrations/#complex-migrations).
@experimental
class TableMigration {
  /// The table to migrate. It is assumed that this table already exists at the
  /// time the migration is running. If you need to create a new table, use
  /// [Migrator.createTable] instead of the more complex [TableMigration].
  final TableInfo affectedTable;

  /// A list of new columns that are known to _not_ exist in the database yet.
  ///
  /// If these columns aren't set through the [columnTransformer], they must
  /// have a default value.
  final List<GeneratedColumn> newColumns;

  /// A map describing how to transform columns of the [affectedTable].
  ///
  /// A key in the map refers to the new column in the table. If you're running
  /// a [TableMigration] to add new columns, those columns doesn't have to exist
  /// in the database yet.
  /// The value associated with a column is the expression to use when
  /// transforming the new table.
  final Map<GeneratedColumn, Expression> columnTransformer;

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
        problematicNewColumns.add(column.$name);
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
