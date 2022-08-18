part of '../query_builder.dart';

/// Base class for generated table classes.
///
/// Drift generates a subclass of [TableInfo] for each table used in a database.
/// This classes contains information about the table's schema (e.g. its
/// [primaryKey] or [$columns]).
///
/// [TableDsl] is the original table class written by the user. For tables
/// defined in drift files, this is the table implementation class itself.
/// [D] is the type of the data class generated from the table.
///
/// To obtain an instance of this class, use a table getter from the database.
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

  /// The unique key of this table. Can be empty if no custom primary key has
  /// been specified.
  ///
  /// Additional to the [Table.primaryKey] columns declared by an user, this
  /// also contains auto-increment integers, which are primary key by default.
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => const [];

  @override
  String get aliasedName => entityName;

  /// The name of the table in the database. Unlike [aliasedName], this can not
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
  /// The [database] instance is used so that the raw values from the companion
  /// can properly be interpreted as the high-level Dart values exposed by the
  /// data class.
  Future<D> mapFromCompanion(
      Insertable<D> companion, DatabaseConnectionUser database) async {
    final asColumnMap = companion.toColumns(false);

    if (asColumnMap.values.any((e) => e is! Variable)) {
      throw ArgumentError('The companion $companion cannot be transformed '
          'into a dataclass as it contains expressions that need to be '
          'evaluated by a database engine.');
    }

    final context = GenerationContext.fromDb(database);
    final rawValues = asColumnMap
        .cast<String, Variable>()
        .map((key, value) => MapEntry(key, value.mapToSimpleValue(context)));

    return map(rawValues);
  }

  @override
  TableInfo<TableDsl, D> createAlias(String alias);

  @override
  bool operator ==(Object other) {
    // tables are singleton instances except for aliases
    if (other is TableInfo) {
      return other.runtimeType == runtimeType &&
          other.aliasedName == aliasedName;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(aliasedName, actualTableName);
}

/// Additional interface for tables in a drift file that have been created with
/// an `CREATE VIRTUAL TABLE STATEMENT`.
mixin VirtualTableInfo<TableDsl extends Table, D> on TableInfo<TableDsl, D> {
  /// Returns the module name and the arguments that were used in the statement
  /// that created this table. In that sense, `CREATE VIRTUAL TABLE <name>
  /// USING <moduleAndArgs>;` can be used to create this table in sql.
  String get moduleAndArgs;
}

/// Static extension members for generated table classes.
///
/// Most of these are accessed internally by drift or by generated code.
extension TableInfoUtils<TableDsl, D> on ResultSetImplementation<TableDsl, D> {
  /// Like [map], but from a [row] instead of the low-level map.
  Future<D> mapFromRow(QueryRow row, {String? tablePrefix}) async {
    return map(row.data, tablePrefix: tablePrefix);
  }

  /// Like [mapFromRow], but returns null if a non-nullable column of this table
  /// is null in [row].
  Future<D?> mapFromRowOrNull(QueryRow row, {String? tablePrefix}) {
    final resolvedPrefix = tablePrefix == null ? '' : '$tablePrefix.';

    final notInRow = $columns
        .where((c) => !c.$nullable)
        .any((e) => row.data['$resolvedPrefix${e.$name}'] == null);

    if (notInRow) return Future.value(null);

    return mapFromRow(row, tablePrefix: tablePrefix);
  }

  /// Like [mapFromRow], but maps columns from the result through [alias].
  ///
  /// This is used internally by drift to support mapping to a table from a
  /// select statement with different column names. For instance, for:
  ///
  /// ```sql
  /// CREATE TABLE tbl (foo, bar);
  ///
  /// query: SELECT foo AS c1, bar AS c2 FROM tbl;
  /// ```
  ///
  /// Drift would generate code to call this method with `'c1': 'foo'` and
  /// `'c2': 'bar'` in [alias].
  Future<D> mapFromRowWithAlias(QueryRow row, Map<String, String> alias) async {
    return map({
      for (final entry in row.data.entries) alias[entry.key]!: entry.value,
    });
  }
}

/// Extension to use the `rowid` of a table in Dart queries.

extension RowIdExtension on TableInfo {
  /// In sqlite, each table that isn't virtual and hasn't been created with the
  /// `WITHOUT ROWID` modified has a [row id](https://www.sqlite.org/rowidtable.html).
  /// When the table has a single primary key column which is an integer, that
  /// column is an _alias_ to the row id in sqlite3.
  ///
  /// If the row id has not explicitly been declared as a column aliasing it,
  /// the [rowId] will not be part of a drift-generated data class. In this
  /// case, the [rowId] getter can be used to refer to a table's row id in a
  /// query.
  Expression<int> get rowId {
    if (withoutRowId || this is VirtualTableInfo) {
      throw ArgumentError('Cannot use rowId on a table without a rowid!');
    }

    return GeneratedColumn<int>('_rowid_', aliasedName, false,
        type: DriftSqlType.int);
  }
}
