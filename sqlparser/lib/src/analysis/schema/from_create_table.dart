part of '../analysis.dart';

/// Reads the [Table] definition from a [CreateTableStatement].
class SchemaFromCreateTable {
  /// Whether we should provide additional type hints for nonstandard `BOOL`
  /// and `DATETIME` columns.
  final bool moorExtensions;

  SchemaFromCreateTable({this.moorExtensions = false});

  Table read(TableInducingStatement stmt) {
    if (stmt is CreateTableStatement) {
      return _readCreateTable(stmt);
    } else if (stmt is CreateVirtualTableStatement) {
      final module = stmt.scope.resolve<Module>(stmt.moduleName);
      return module.parseTable(stmt);
    }

    throw AssertionError('Unknown table statement');
  }

  Table _readCreateTable(CreateTableStatement stmt) {
    return Table(
      name: stmt.tableName,
      resolvedColumns: [for (var def in stmt.columns) _readColumn(def)],
      withoutRowId: stmt.withoutRowId,
      tableConstraints: stmt.tableConstraints,
      definition: stmt,
    );
  }

  TableColumn _readColumn(ColumnDefinition definition) {
    final typeName = definition.typeName.toUpperCase();

    final type = resolveColumnType(typeName);
    final nullable = !definition.constraints.any((c) => c is NotNull);

    final resolvedType = type.withNullable(nullable);

    return TableColumn(
      definition.columnName,
      resolvedType,
      definition: definition,
    );
  }

  /// Resolves a column type via its typename, see the linked rules below.
  /// Additionally, if [moorExtensions] are enabled, we support [IsBoolean] and
  /// [IsDateTime] hints if the type name contains `BOOL` or `DATE`,
  /// respectively.
  /// https://www.sqlite.org/datatype3.html#determination_of_column_affinity
  ResolvedType resolveColumnType(String typeName) {
    if (typeName == null) {
      return const ResolvedType(type: BasicType.blob);
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

    if (moorExtensions) {
      if (upper.contains('BOOL')) {
        return const ResolvedType.bool();
      }
      if (upper.contains('DATE')) {
        return const ResolvedType(type: BasicType.int, hint: IsDateTime());
      }
    }

    return const ResolvedType(type: BasicType.real);
  }

  /// Looks up the correct column affinity for a declared type name with the
  /// rules described here:
  /// https://www.sqlite.org/datatype3.html#determination_of_column_affinity
  @visibleForTesting
  BasicType columnAffinity(String typeName) => resolveColumnType(typeName).type;
}
