import 'package:sally/src/queries/expressions/limit.dart';
import 'package:sally/src/queries/expressions/where.dart';
import 'package:sally/src/queries/generation_context.dart';
import 'package:sally/src/queries/predicates/predicate.dart';
import 'package:sally/src/queries/table_structure.dart';

abstract class SqlStatement {
  GenerationContext _buildQuery();
}

abstract class StatementForExistingData<Table, Result> extends SqlStatement {
  final TableStructure<Table, Result> _table;

  StatementForExistingData(this._table);

  WhereExpression _where;
  LimitExpression _limit;

  Future<List<Result>> get() async {
    final ctx = _buildQuery();
    final sql = ctx.buffer.toString();
    final vars = ctx.boundVariables;

    final result = await _table.executor.executeQuery(sql, vars);
    return result.map(_table.parse).toList();
  }

  Future<Result> single() async {
    // limit to one item, using the existing offset if it exists
    _limit = LimitExpression(1, _limit?.offset ?? 0);

    return (await get()).single;
  }

  StatementForExistingData<Table, Result> where(
      Predicate extractor(Table tbl)) {
    final addedPredicate = extractor(_table.asTable);

    if (_where != null) {
      // merge existing where expression together with new one by and-ing them
      // together.
      _where = WhereExpression(_where.predicate.and(addedPredicate));
    } else {
      _where = WhereExpression(addedPredicate);
    }

    return this;
  }

  StatementForExistingData<Table, Result> limit({int amount, int offset}) {
    _limit = LimitExpression(amount, offset);
    return this;
  }
}

class SelectStatement<T, R> extends StatementForExistingData<T, R> {
  SelectStatement(TableStructure<T, R> table) : super(table);

  @override
  GenerationContext _buildQuery() {
    GenerationContext context = GenerationContext();
    context.buffer.write('SELECT * FROM ');
    context.buffer.write(_table.sqlTableName);
    context.buffer.write(' ');

    if (_where != null) _where.writeInto(context);
    if (_limit != null) _limit.writeInto(context);

    return context;
  }
}
