import '../../connections/result_set.dart';
import '../../runtime/database/connection_user.dart';
import '../compiler.dart';
import '../results.dart';
import '../schema/result_set.dart';
import '../schema/table.dart';

/// A `RETURNING *` clause that can appear as part of an `INSERT`, `UPDATE` or
/// `DELETE` statement.
final class ReturningClause<Row extends Object,
    RS extends GeneratedTable<Row, RS>> implements SqlComponent {
  /// The generated [ResultSetStructure] representing columns for this
  /// `RETURNING` clause.
  final ResultSetStructure structure = ResultSetStructure();

  final ResultSet<Row, RS> _resultSet;

  /// Creates a `RETURNING` clause for the given [resultSet].
  ReturningClause(this._resultSet) {
    // Note: We currently only generate `RETURNING *` clauses returning columns
    // for a single table.
    final columnPositions = <ColumnPosition>[];
    for (final (i, column) in _resultSet.columns.indexed) {
      final position = (index: i, name: column.name);
      structure.expressions[column] = position;
      columnPositions.add(position);
    }

    structure.tables[_resultSet] = columnPositions;
  }

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addReturningClause(this);
  }

  /// Maps rows from the given [result] using the result set for this
  /// `RETURNING` clause.
  List<Row> interpretResults(
      DatabaseConnectionUser database, QueryResult result) {
    final rows = DriftResultSet(structure, result.resultSet!, database.dialect);
    final mapper = _resultSet.createMapperToDart(rows);

    return [
      for (final row in rows) mapper(row)!,
    ];
  }
}
