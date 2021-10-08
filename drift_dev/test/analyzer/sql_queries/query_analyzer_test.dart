//@dart=2.9
import 'package:drift_dev/moor_generator.dart';
import 'package:drift_dev/src/analyzer/runner/results.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  test('respects explicit type arguments', () async {
    final state = TestState.withContent({
      'foo|lib/main.moor': ''' 
bar(?1 AS TEXT, :foo AS BOOLEAN): SELECT ?, :foo;
      ''',
    });

    await state.runTask('package:foo/main.moor');
    final file = state.file('package:foo/main.moor');
    state.close();

    expect(file.errors.errors, isEmpty);
    final content = file.currentResult as ParsedMoorFile;

    final query = content.resolvedQueries.single;
    expect(query, const TypeMatcher<SqlSelectQuery>());

    final resultSet = (query as SqlSelectQuery).resultSet;
    expect(resultSet.matchingTable, isNull);
    expect(resultSet.columns.map((c) => c.name), ['?', ':foo']);
    expect(resultSet.columns.map((c) => c.type),
        [ColumnType.text, ColumnType.boolean]);
  });

  test('reads REQUIRED syntax', () async {
    final state = TestState.withContent({
      'foo|lib/main.moor': ''' 
bar(REQUIRED ?1 AS TEXT OR NULL, REQUIRED :foo AS BOOLEAN): SELECT ?, :foo;
      ''',
    });

    await state.runTask('package:foo/main.moor');
    final file = state.file('package:foo/main.moor');
    state.close();

    expect(file.errors.errors, isEmpty);
    final content = file.currentResult as ParsedMoorFile;

    final query = content.resolvedQueries.single;
    expect(
      query.variables,
      allOf(
        hasLength(2),
        everyElement(isA<FoundVariable>()
            .having((e) => e.isRequired, 'isRequired', isTrue)),
      ),
    );
  });
}
