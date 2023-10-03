part of '../analysis.dart';

/// Reads the [Table] definition from a [CreateTableStatement].
class SchemaFromCreateTable {
  /// Whether we should provide additional type hints for nonstandard `BOOL`
  /// and `DATETIME` columns.
  final bool driftExtensions;

  /// Whether the `DATE` column type (only respected if [driftExtensions] are
  /// enabled) should be reported as a text column instead of an int column.
  final bool driftUseTextForDateTime;

  final AnalyzeStatementOptions? statementOptions;

  const SchemaFromCreateTable({
    this.driftExtensions = false,
    this.driftUseTextForDateTime = false,
    this.statementOptions,
  });

  /// Reads a [Table] schema from the [stmt] inducing a table (either a
  /// [CreateTableStatement] or a [CreateVirtualTableStatement]).
  ///
  /// This method might throw an exception if the table could not be read.
  Table read(TableInducingStatement stmt) {
    if (stmt is CreateTableStatement) {
      return _readCreateTable(stmt);
    } else if (stmt is CreateVirtualTableStatement) {
      final module = stmt.scope.rootScope.knownModules[stmt.moduleName];

      if (module == null) {
        throw CantReadSchemaException('Unknown module "${stmt.moduleName}", '
            'did you register it?');
      }

      return module.parseTable(stmt);
    }

    throw AssertionError('Unknown table statement');
  }

  /// Creates a [View] from a [CreateViewStatement]. The `CREATE VIEW` statement
  /// must be fully resolved through [context] when calling this method.
  ///
  /// Example:
  /// ```dart
  /// // this will run analysis on the inner select statement and resolve columns
  /// final ctx = engine.analyze('CREATE VIEW ...');
  /// final createViewStmt = ctx.root as CreateViewStatement;
  ///
  /// final view = const SchemaFromCreateTable().readView(ctx, createViewStmt);
  /// ```
  View readView(AnalysisContext context, CreateViewStatement stmt) {
    final columnsFromSelect = stmt.query.resolvedColumns!;
    final overriddenNames = stmt.columns ?? const [];

    final viewColumns = <ViewColumn>[];

    for (var i = 0; i < columnsFromSelect.length; i++) {
      final column = columnsFromSelect[i];

      // overriddenNames might be shorter than the columns. That's not a valid
      // CREATE VIEW statement, but we try not to crash.
      final name = i < overriddenNames.length ? overriddenNames[i] : null;

      viewColumns.add(ViewColumn(column, context.typeOf(column).type, name));
    }

    return View(
      name: stmt.viewName,
      resolvedColumns: viewColumns,
      definition: stmt,
    );
  }

  Table _readCreateTable(CreateTableStatement stmt) {
    final primaryKey = _primaryKeyOf(stmt);

    return Table(
      name: stmt.tableName,
      resolvedColumns: [
        for (var def in stmt.columns)
          _readColumn(
            def,
            isStrict: stmt.isStrict,
            primaryKeyColumnsInStrictTable: stmt.isStrict ? primaryKey : null,
          )
      ],
      withoutRowId: stmt.withoutRowId,
      isStrict: stmt.isStrict,
      tableConstraints: stmt.tableConstraints,
      definition: stmt,
    );
  }

  Set<String> _primaryKeyOf(CreateTableStatement stmt) {
    final columnsInPk = <String>{};

    for (final tableConstraint
        in stmt.tableConstraints.whereType<KeyClause>()) {
      if (tableConstraint.isPrimaryKey) {
        for (final ref in tableConstraint.columns) {
          final expr = ref.expression;
          if (expr is Reference) {
            columnsInPk.add(expr.columnName);
          }
        }
      }
    }

    for (final column in stmt.columns) {
      for (final constraint in column.constraints) {
        if (constraint is PrimaryKeyColumn) {
          columnsInPk.add(column.columnName);
        }
      }
    }

    return columnsInPk;
  }

  TableColumn _readColumn(ColumnDefinition definition,
      {required bool isStrict,
      required Set<String>? primaryKeyColumnsInStrictTable}) {
    final type = resolveColumnType(definition.typeName, isStrict: isStrict);

    // Column is nullable if it doesn't contain a `NotNull` constraint and it's
    // not part of a PK in a strict table.
    final nullable = !definition.constraints.any((c) => c is NotNull) &&
        primaryKeyColumnsInStrictTable?.contains(definition.columnName) != true;

    final resolvedType = type.withNullable(nullable);

    return TableColumn(
      definition.columnName,
      resolvedType,
      definition: definition,
      isGenerated: definition.constraints.any((c) => c is GeneratedAs),
    );
  }

  /// Resolves a column type via its typename, see the linked rules below.
  /// Additionally, if [driftExtensions] are enabled, we support [IsBoolean] and
  /// [IsDateTime] hints if the type name contains `BOOL` or `DATE`,
  /// respectively.
  /// https://www.sqlite.org/datatype3.html#determination_of_column_affinity
  ResolvedType resolveColumnType(String? typeName, {bool isStrict = false}) {
    if (typeName == null) {
      return const ResolvedType(type: BasicType.blob);
    }

    // S if a custom resolver is installed and yields a type for this column:
    final custom = statementOptions?.resolveTypeFromText?.call(typeName);
    if (custom != null) {
      return custom;
    }

    final upper = typeName.toUpperCase();
    if (upper.contains('INT')) {
      return const ResolvedType(type: BasicType.int);
    }
    if (upper.contains('CHAR') ||
        upper.contains('CLOB') ||
        upper.contains('TEXT')) {
      return const ResolvedType(type: BasicType.text);
    }

    if (upper.contains('BLOB')) {
      return const ResolvedType(type: BasicType.blob);
    }

    if (isStrict && upper == 'ANY') {
      return const ResolvedType(type: BasicType.any);
    }

    if (driftExtensions) {
      if (upper.contains('BOOL')) {
        return const ResolvedType.bool();
      }
      if (upper.contains('DATE')) {
        return ResolvedType(
          type: driftUseTextForDateTime ? BasicType.text : BasicType.int,
          hints: const [IsDateTime()],
        );
      }

      if (upper.contains('ENUMNAME')) {
        return const ResolvedType(type: BasicType.text);
      }

      if (upper.contains('ENUM')) {
        return const ResolvedType(type: BasicType.int);
      }
    }

    return const ResolvedType(type: BasicType.real);
  }

  bool isValidTypeNameForStrictTable(String typeName) {
    if (driftExtensions) {
      // Drift_dev will use resolveColumnType to analyze the actual type of the
      // column, and the generated code will always use a valid type name for
      // that type. So, anything goes!
      return true;
    } else {
      // See https://www.sqlite.org/stricttables.html
      const allowed = {'INT', 'INTEGER', 'REAL', 'TEXT', 'BLOB', 'ANY'};
      final upper = typeName.toUpperCase();

      return allowed.contains(upper);
    }
  }

  /// Looks up the correct column affinity for a declared type name with the
  /// rules described here:
  /// https://www.sqlite.org/datatype3.html#determination_of_column_affinity
  @visibleForTesting
  BasicType? columnAffinity(String? typeName) =>
      resolveColumnType(typeName).type;
}

/// Thrown when a table schema could not be read.
class CantReadSchemaException implements Exception {
  final String message;

  CantReadSchemaException(this.message);

  @override
  String toString() {
    return 'Could not read table schema: $message';
  }
}
