import '../../connections/connection.dart';
import '../../connections/result_set.dart';
import '../../runtime/database/connection_user.dart';
import '../../runtime/selectable.dart';
import '../clauses/where.dart';
import '../compiler.dart';
import '../expressions/expression.dart';
import '../results.dart';
import '../schema/result_set.dart';
import 'statement.dart';
import 'query.dart';

sealed class BaseSelectStatement<Row> extends SqlStatement
    with Selectable<Row> {
  final ResultSetStructure structure = ResultSetStructure();

  bool distinct = false;
  final List<FromClauseElement> from = [];

  WhereClause? whereClause;

  /// The database this statement should be sent to.
  DatabaseConnectionUser _database;

  BaseSelectStatement(this._database);

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

  Row _mapFromDb(DriftRow row);

  @override
  Future<List<Row>> get() async {
    final session = await _database.currentSession();
    final query = StatementInfo(_database.dialect.compile(this));
    final results = await session.execute(query);
    final mapped =
        DriftResultSet(structure, results.resultSet!, _database.dialect);

    return mapped.map(_mapFromDb).toList();
  }

  @override
  Stream<List<Row>> watch() {
    // TODO: implement watch
    throw UnimplementedError();
  }
}

sealed class FromClauseElement implements SqlComponent {}

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
        RS extends ResultSet<Row, RS>> extends BaseSelectStatement<Row>
    with
        SingleTableStatementMixin<Row, RS,
            SingleTableSelectStatement<Row, RS>> {
  @override
  final ResultSet<Row, RS> resultSet;

  SingleTableSelectStatement(super._database, this.resultSet) {
    final positions = <ColumnPosition>[];
    for (final (i, column) in resultSet.columns.indexed) {
      final position = (name: column.name, index: i);
      structure.expressions[column] = position;
      positions.add(position);
    }

    structure.tables[resultSet] = positions;
    from.add(TableReference(resultSet));
  }

  @override
  SingleTableSelectStatement<Row, RS> asSelf() => this;

  @override
  Row _mapFromDb(DriftRow row) => row.readTable(resultSet);
}
