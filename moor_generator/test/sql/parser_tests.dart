import 'package:moor_generator/src/sql/parser/parser.dart';
import 'package:test_api/test_api.dart';

void main() {
  test('test', () {
    final grammar = SqlGrammar();
    final semantics = SemanticSqlParser();

    print(grammar.parse("SELECT 'lol' AS test"));
    print(semantics.parse('SELECT *, tableName.*, NULL AS id'));
  });
}
