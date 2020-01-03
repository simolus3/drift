import 'package:moor_generator/src/analyzer/errors.dart';
import 'package:moor_generator/src/analyzer/sql_queries/query_handler.dart';
import 'package:moor_generator/src/analyzer/sql_queries/type_mapping.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../utils.dart';

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

  group('warns about insert column count mismatch', () {
    TestState state;

    Future<void> expectError() async {
      final file = await state.analyze('package:foo/a.moor');
      expect(
        file.errors.errors,
        contains(const TypeMatcher<MoorError>().having(
            (e) => e.message, 'message', 'Expected tuple to have 2 values')),
      );
    }

    test('in top-level queries', () async {
      state = TestState.withContent({
        'foo|lib/a.moor': '''
CREATE TABLE foo (
  id INT NOT NULL PRIMARY KEY AUTOINCREMENT,
  context VARCHAR
);

test: INSERT INTO foo VALUES (?)
        ''',
      });
      await expectError();
    });

    test('in CREATE TRIGGER statements', () async {
      state = TestState.withContent({
        'foo|lib/a.moor': '''
CREATE TABLE foo (
  id INT NOT NULL PRIMARY KEY AUTOINCREMENT,
  context VARCHAR
);

CREATE TRIGGER my_trigger AFTER DELETE ON foo BEGIN
  INSERT INTO foo VALUES (old.context);
END;
        ''',
      });
      await expectError();
    });

    test('in @create statements', () async {
      state = TestState.withContent({
        'foo|lib/a.moor': '''
CREATE TABLE foo (
  id INT NOT NULL PRIMARY KEY AUTOINCREMENT,
  context VARCHAR
);

@create: INSERT INTO foo VALUES (old.context);
        ''',
      });
      await expectError();
    });
  });
}
