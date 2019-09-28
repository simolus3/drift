part of '../analysis.dart';

/// Reads the [Table] definition from a [CreateTableStatement].
class SchemaFromCreateTable {
  Table read(CreateTableStatement stmt) {
    return Table(
      name: stmt.tableName,
      resolvedColumns: [for (var def in stmt.columns) _readColumn(def)],
      withoutRowId: stmt.withoutRowId,
      tableConstraints: stmt.tableConstraints,
      definition: stmt,
    );
  }

  TableColumn _readColumn(ColumnDefinition definition) {
    final affinity = columnAffinity(definition.typeName);
    final nullable = !definition.constraints.any((c) => c is NotNull);

    final resolvedType = ResolvedType(type: affinity, nullable: nullable);

    return TableColumn(
      definition.columnName,
      resolvedType,
      definition: definition,
    );
  }

  /// Looks up the correct column affinity for a declared type name with the
  /// rules described here:
  /// https://www.sqlite.org/datatype3.html#determination_of_column_affinity
  @visibleForTesting
  BasicType columnAffinity(String typeName) {
    if (typeName == null) {
      return BasicType.blob;
    }

    final upper = typeName.toUpperCase();
    if (upper.contains('INT')) {
      return BasicType.int;
    }
    if (upper.contains('CHAR') ||
        upper.contains('CLOB') ||
        upper.contains('TEXT')) {
      return BasicType.text;
    }

    if (upper.contains('BLOB')) {
      return BasicType.blob;
    }

    return BasicType.real;
  }
}
