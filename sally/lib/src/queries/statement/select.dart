import 'package:sally/src/queries/expressions/expressions.dart';
import 'package:sally/src/queries/statement/statements.dart';
import 'package:sally/src/queries/table_structure.dart';

class SelectStatement<Table, Result> with Limitable, WhereFilterable<Table, Result> {

  SelectStatement(TableStructure<Table, Result> table) {
    super.table = table;
  }

  GenerationContext _buildQuery() {
    GenerationContext context = GenerationContext();
    context.buffer.write('SELECT * FROM ');
    context.buffer.write(table.sqlTableName);
    context.buffer.write(' ');

    if (hasWhere) whereExpression.writeInto(context);
    if (hasLimit) limitExpression.writeInto(context);

    return context;
  }

  /// Executes the select statement on the database and maps the returned rows
  /// to the right dataclass.
  Future<List<Result>> get() async {
    final ctx = _buildQuery();
    final sql = ctx.buffer.toString();
    final vars = ctx.boundVariables;

    final result = await table.executor.executeQuery(sql, vars);
    return result.map(table.parse).toList();
  }

  /// Similar to [get], but it will only load one item by setting [limit()]
  /// appropriately. This method will throw if no results where found. If you're
  /// ok with no result existing, try [singleOrNull] instead.
  Future<Result> single() async {
    final element = singleOrNull();
    if (element == null)
      throw StateError("No item was returned by the query called with single()");

    return element;
  }

  /// Similar to [get], but only uses one row of the result by setting the limit
  /// accordingly. If no item was found, null will be returned instead.
  Future<Result> singleOrNull() async {
    // limit to one item, using the existing offset if it exists
    limitExpression = LimitExpression(1, limitExpression.offset ?? 0);

    final results = await get();
    if (results.isEmpty)
      return null;
    return results.single;
  }

}

