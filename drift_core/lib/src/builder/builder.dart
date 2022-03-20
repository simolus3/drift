import '../dialect.dart';
import '../expressions/expression.dart';
import '../statements/select.dart';
import 'context.dart';

class QueryBuilder {
  final SqlDialect _dialect;

  QueryBuilder(this._dialect);

  SelectStatement select(List<Expression> expressions) {
    return SelectStatement(expressions);
  }

  GenerationContext newContext() => GenerationContext(_dialect);
}
