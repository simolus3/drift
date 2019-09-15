import 'package:moor_generator/src/analyzer/sql_queries/query_handler.dart';
import 'package:moor_generator/src/analyzer/sql_queries/type_mapping.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

void main() {
  final engine = SqlEngine(useMoorExtensions: true);
  final mapper = TypeMapper();

  test('warns when a result column is unresolved', () {
    final result = engine.analyze('SELECT ?;');
    final moorQuery = QueryHandler('query', result, mapper).handle();

    expect(moorQuery.lints,
        anyElement((AnalysisError q) => q.message.contains('unknown type')));
  });

  test('warns when the result depends on a Dart template', () {
    final result = engine.analyze(r"SELECT 'string' = $expr;");
    final moorQuery = QueryHandler('query', result, mapper).handle();

    expect(moorQuery.lints,
        anyElement((AnalysisError q) => q.message.contains('Dart template')));
  });
}
