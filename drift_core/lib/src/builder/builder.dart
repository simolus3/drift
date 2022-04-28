import '../dialect.dart';
import '../schema.dart';
import '../statements/delete.dart';
import '../statements/select.dart';
import 'context.dart';

class QueryBuilder {
  final SqlDialect _dialect;

  QueryBuilder(this._dialect);

  GenerationContext build(
      SqlComponent Function(QueryBuilder builder) createStmt) {
    final stmt = createStmt(this);
    final context = newContext();
    stmt.writeInto(context);
    return context;
  }

  SelectStatement select(List<SelectColumn> expressions,
      {bool distinct = false}) {
    return SelectStatement(expressions, distinct: distinct);
  }

  DeleteStatement delete({required SchemaTable from}) {
    return DeleteStatement(from);
  }

  SqlComponent createTable(SchemaTable table) {
    return _dialect.createTable(table);
  }

  GenerationContext newContext() => GenerationContext(_dialect);
}
