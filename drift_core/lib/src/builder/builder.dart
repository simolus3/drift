import '../dialect.dart';
import '../expressions/expression.dart';
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

  SelectStatement select(List<Expression> expressions) {
    return SelectStatement(expressions);
  }

  DeleteStatement delete({required SchemaTable from}) {
    return DeleteStatement(from);
  }

  GenerationContext newContext() => GenerationContext(_dialect);
}
