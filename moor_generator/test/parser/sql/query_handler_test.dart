import 'package:moor_generator/src/analyzer/sql_queries/query_handler.dart';
import 'package:moor_generator/src/analyzer/sql_queries/type_mapping.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

void main() {
  test('throws when variable indexes are skipped', () {
    expect(_createHandler('', 'SELECT ?2').handle, throwsStateError);
    expect(_createHandler('', 'SELECT ?1 = ?3').handle, throwsStateError);
    expect(_createHandler('', 'SELECT ?1 = ?3 OR ?2').handle, returnsNormally);
  });
}

QueryHandler _createHandler(String name, String sql) {
  final mapper = TypeMapper();
  final parsed = SqlEngine().analyze(sql);
  return QueryHandler(name, parsed, mapper);
}
