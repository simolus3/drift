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
  GenerationContext _createContext({bool supportsVariables = false}) {
    return GenerationContext.fromDb(database,
        supportsVariables: supportsVariables);
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

          context.buffer.write(column.escapedNameFor(context.dialect));

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

            context.buffer.write(column.escapedNameFor(context.dialect));

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

    final options = [
      if (dslTable.withoutRowId) 'WITHOUT ROWID',
      if (dslTable.isStrict) 'STRICT'
    ].join(', ');

    if (options.isNotEmpty) {
      context.buffer
        ..write(' ')
        ..write(options);
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
    return database.customStatement(sql, args);
  }

  /// A helper used by drift internally to implement the [step-by-step](https://drift.simonbinder.eu/docs/advanced-features/migrations/#step-by-step)
  /// migration feature.
  ///
  /// This method implements an [OnUpgrade] callback by repeatedly invoking
  /// [step] with the current version, assuming that [step] will perform an
  /// upgrade from that version to the version returned by the callback.
  @Deprecated(
      'Re-generate code so that it uses `VersionedSchema.stepByStepHelper`')
  static OnUpgrade stepByStepHelper({
    required MigrationStepWithVersion step,
  }) {
    return VersionedSchema.stepByStepHelper(step: step);
  }
}
