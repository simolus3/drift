import 'package:drift3_preview/drift.dart';
import 'package:meta/meta.dart';

/// A row storing parsed result sets and computed expressions for the manager
/// API.
final class ManagerResultRow {
  final Map<ResultSet, Object> _loadedTables;
  final Map<Expression, Object?> _loadedExpressions;

  /// Creates a result row from parsed tables and expressions.
  ManagerResultRow.fromValues({
    Map<ResultSet, Object>? tables,
    Map<Expression, Object?>? expressions,
  }) : _loadedTables = tables ?? {},
       _loadedExpressions = expressions ?? {};

  /// Creates a result row from an underlying drift result row.
  factory ManagerResultRow.fromDriftRow(DriftRow row) {
    final structure = row.resultSet.structure;
    final loadedTables = <ResultSet, Object>{};
    final loadedExpressions = <Expression, Object?>{};

    for (final table in structure.tables.keys) {
      final parsedRow = row.readAnyTableOrNull(table);
      if (parsedRow != null) {
        loadedTables[table] = parsedRow;
      }
    }

    for (final expr in structure.expressions.keys) {
      loadedExpressions[expr] = row.read(expr);
    }

    return .fromValues(tables: loadedTables, expressions: loadedExpressions);
  }

  /// Reads all data that belongs to the given [table] from this row.
  ///
  /// If this row does not contain non-null columns of the [table], this method
  /// will throw an [ArgumentError].
  Row readTable<RS extends ResultSet<Row, RS>, Row extends Object>(RS table) {
    if (!_loadedTables.containsKey(table)) {
      throw ArgumentError(
        'Invalid table passed to readTable: ${table.aliasOrName}. This row '
        'does not contain values for that table.',
      );
    }

    return _loadedTables[table] as Row;
  }

  /// Reads all data that belongs to the given [table] from this row.
  ///
  /// Returns `null` if this row does not contain non-null values of the
  /// [table].
  ///
  /// See also: [readTable], which throws instead of returning `null`.
  Row? readTableOrNull<RS extends ResultSet<Row, RS>, Row extends Object>(
    RS table,
  ) {
    return _loadedTables[table] as Row?;
  }

  /// Reads a single column from an [expr]. The expression must have been added
  /// as a column.
  D? read<D extends Object>(Expression<D> expr) {
    if (_loadedExpressions.containsKey(expr)) {
      return _loadedExpressions[expr] as D?;
    }

    throw ArgumentError(
      'Invalid call to read(): $expr. This result set does not have a column '
      'for that expression.',
    );
  }
}

@internal
extension InternalRow on ManagerResultRow {
  void addData(ResultSet table, Object data) {
    _loadedTables[table] = data;
  }
}
