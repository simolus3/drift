import '../../connections/result_set.dart';
import '../compiler.dart';
import '../expressions/expression.dart';
import '../results.dart';
import '../schema/column.dart';
import '../schema/result_set.dart';
import 'statement.dart';

sealed class BaseSelectStatement<Row> extends SqlStatement {
  final ResultSetStructure structure = ResultSetStructure();

  final List<FromClauseElement> from = [];

  ColumnPosition get _nextPosition {
    final index = structure.expressions.length;
    return (name: 'c$index', index: index);
  }

  void addColumn(Expression expression) {
    structure.expressions[expression] ??= _nextPosition;
  }

  void addResultSet(ResultSet resultSet) {
    if (structure.tables.containsKey(resultSet)) {
      throw StateError(
          'Result set $resultSet has been added to select multiple times, please use an alias');
    }

    final positions = <ColumnPosition>[];
    for (final column in resultSet.columns) {
      final columnPosition = _nextPosition;
      positions.add(columnPosition);
      structure.expressions[column] = columnPosition;
    }

    structure.tables[resultSet] = positions;
  }

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addSelectStatement(this);
  }
}

sealed class FromClauseElement extends SqlComponent {}

//final class Join extends FromClauseElement {}

final class TableReference extends FromClauseElement {
  final ResultSet resultSet;

  TableReference(this.resultSet);

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addTableReference(this);
  }
}

final class SingleTableSelectStatement<Row extends Object,
    RS extends ResultSet<Row, RS>> extends BaseSelectStatement<Row> {
  final ResultSet<Row, RS> _resultSet;

  SingleTableSelectStatement(this._resultSet) {
    final positions = <ColumnPosition>[];
    for (final (i, column) in _resultSet.columns.indexed) {
      final position = (name: column.name, index: i);
      structure.expressions[column] = position;
      positions.add(position);
    }

    structure.tables[_resultSet] = positions;
    from.add(TableReference(_resultSet));
  }
}
