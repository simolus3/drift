part of '../query_builder.dart';

/// Base class for generated classes. [TableDsl] is the type specified by the
/// user that extends [Table], [D] is the type of the data class
/// generated from the table.
mixin TableInfo<TableDsl extends Table, D> on Table
    implements DatabaseSchemaEntity, ResultSetImplementation<TableDsl, D> {
  @override
  TableDsl get asDslTable => this as TableDsl;

  /// The primary key of this table. Can be empty if no custom primary key has
  /// been specified.
  ///
  /// Additional to the [Table.primaryKey] columns declared by an user, this
  /// also contains auto-increment integers, which are primary key by default.
  Set<GeneratedColumn> get $primaryKey => const {};

  // ensure the primaryKey getter is consistent with $primaryKey, which can
  // contain additional columns.
  @override
  Set<Column> get primaryKey => $primaryKey;

  /// The table name in the sql table. This can be an alias for the actual table
  /// name. See [actualTableName] for a table name that is not aliased.
  @Deprecated('Use aliasedName instead')
  String get $tableName => aliasedName;

  @override
  String get aliasedName => entityName;

  /// The name of the table in the database. Unless [$tableName], this can not
  /// be aliased.
  String get actualTableName;

  @override
  String get entityName => actualTableName;

  Map<String, GeneratedColumn>? _columnsByName;

  /// Gets all [$columns] in this table, indexed by their (non-escaped) name.
  Map<String, GeneratedColumn> get columnsByName {
    return _columnsByName ??= {
      for (final column in $columns) column.$name: column
    };
  }

  /// Validates that the given entity can be inserted into this table, meaning
  /// that it respects all constraints (nullability, text length, etc.).
  VerificationContext validateIntegrity(Insertable<D> instance,
      {bool isInserting = false}) {
    // default behavior when users chose to not verify the integrity (build time
    // option)
    return const VerificationContext.notEnabled();
  }

  /// Converts a [companion] to the real model class, [D].
  ///
  /// Values that are [Value.absent] in the companion will be set to `null`.
  D mapFromCompanion(Insertable<D> companion) {
    final asColumnMap = companion.toColumns(false);

    if (asColumnMap.values.any((e) => e is! Variable)) {
      throw ArgumentError('The companion $companion cannot be transformed '
          'into a dataclass as it contains expressions that need to be '
          'evaluated by a database engine.');
    }

    final context = GenerationContext(SqlTypeSystem.defaultInstance, null);
    final rawValues = asColumnMap
        .cast<String, Variable>()
        .map((key, value) => MapEntry(key, value.mapToSimpleValue(context)));

    return map(rawValues);
  }

  @override
  TableInfo<TableDsl, D> createAlias(String alias);

  @override
  bool operator ==(dynamic other) {
    // tables are singleton instances except for aliases
    if (other is TableInfo) {
      return other.runtimeType == runtimeType && other.$tableName == $tableName;
    }
    return false;
  }

  @override
  int get hashCode => $mrjf($mrjc(runtimeType.hashCode, $tableName.hashCode));
}

/// Additional interface for tables in a moor file that have been created with
/// an `CREATE VIRTUAL TABLE STATEMENT`.
mixin VirtualTableInfo<TableDsl extends Table, D> on TableInfo<TableDsl, D> {
  /// Returns the module name and the arguments that were used in the statement
  /// that created this table. In that sense, `CREATE VIRTUAL TABLE <name>
  /// USING <moduleAndArgs>;` can be used to create this table in sql.
  String get moduleAndArgs;
}

/// Static extension members for generated table classes.
///
/// Most of these are accessed internally by moor or by generated code.
extension TableInfoUtils<TableDsl, D> on ResultSetImplementation<TableDsl, D> {
  /// Like [map], but from a [row] instead of the low-level map.
  D mapFromRow(QueryRow row, {String? tablePrefix}) {
    return map(row.data, tablePrefix: tablePrefix);
  }

  /// Like [mapFromRow], but returns null if a non-nullable column of this table
  /// is null in [row].
  D? mapFromRowOrNull(QueryRow row, {String? tablePrefix}) {
    final resolvedPrefix = tablePrefix == null ? '' : '$tablePrefix.';

    final notInRow = $columns
        .where((c) => !c.$nullable)
        .any((e) => row.data['$resolvedPrefix${e.$name}'] == null);

    if (notInRow) return null;

    return mapFromRow(row, tablePrefix: tablePrefix);
  }

  /// Like [mapFromRow], but maps columns from the result through [alias].
  ///
  /// This is used internally by moor to support mapping to a table from a
  /// select statement with different column names. For instance, for:
  ///
  /// ```sql
  /// CREATE TABLE tbl (foo, bar);
  ///
  /// query: SELECT foo AS c1, bar AS c2 FROM tbl;
  /// ```
  ///
  /// Moor would generate code to call this method with `'c1': 'foo'` and
  /// `'c2': 'bar'` in [alias].
  D mapFromRowWithAlias(QueryRow row, Map<String, String> alias) {
    return map({
      for (final entry in row.data.entries) alias[entry.key]!: entry.value,
    });
  }
}
