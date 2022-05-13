import 'package:drift_dev/moor_generator.dart';
import 'package:drift_dev/src/analyzer/errors.dart';
import 'package:drift_dev/src/analyzer/sql_queries/query_handler.dart';
import 'package:drift_dev/src/analyzer/sql_queries/type_mapping.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  final engine = SqlEngine(EngineOptions(
      useDriftExtensions: true, enabledExtensions: const [Json1Extension()]));
  final mapper = TypeMapper();

  final fakeQuery = DeclaredDartQuery('query', 'sql');

  test('warns when a result column is unresolved', () {
    final result = engine.analyze('SELECT ?;');
    final moorQuery = QueryHandler(result, mapper).handle(fakeQuery);

    expect(moorQuery.lints,
        anyElement((AnalysisError q) => q.message!.contains('unknown type')));
  });

  test('warns when the result depends on a Dart template', () {
    final result = engine.analyze(r"SELECT 'string' = $expr;");
    final moorQuery = QueryHandler(result, mapper).handle(fakeQuery);

    expect(moorQuery.lints,
        anyElement((AnalysisError q) => q.message!.contains('Dart template')));
  });

  test('warns when nested results refer to table-valued functions', () {
    final result = engine.analyze("SELECT json_each.** FROM json_each('')");
    final moorQuery = QueryHandler(result, mapper).handle(fakeQuery);

    expect(
      moorQuery.lints,
      contains(isA<AnalysisError>().having((e) => e.message, 'message',
          contains('must refer to a table directly'))),
    );
  });

  test('warns about default values outside of expressions', () async {
    final state = TestState.withContent({
      'foo|lib/a.moor': r'''
CREATE TABLE foo (
  id INT NOT NULL PRIMARY KEY,
  content VARCHAR
);

all ($limit = 3): SELECT * FROM foo LIMIT $limit;
      ''',
    });

    final result = await state.analyze('package:foo/a.moor');
    state.close();

    expect(
      result.errors.errors,
      contains(isA<MoorError>().having(
        (e) => e.message,
        'message',
        contains('only supported for expressions'),
      )),
    );
  });

  test('warns when placeholder are used in insert with columns', () async {
    final state = TestState.withContent({
      'foo|lib/a.moor': r'''
CREATE TABLE foo (
  id INT NOT NULL PRIMARY KEY,
  content VARCHAR
);

in: INSERT INTO foo (id) $placeholder;
      ''',
    });

    final result = await state.analyze('package:foo/a.moor');
    state.close();

    expect(
      result.errors.errors,
      contains(isA<MoorError>().having(
        (e) => e.message,
        'message',
        contains("Dart placeholders can't be used here"),
      )),
    );
  });

  test(
    'warns when nested results appear in compound statements',
    () async {
      final state = TestState.withContent({
        'foo|lib/a.moor': '''
CREATE TABLE foo (
  id INT NOT NULL PRIMARY KEY,
  content VARCHAR
);

all: SELECT foo.** FROM foo UNION ALL SELECT foo.** FROM foo;
      ''',
      });

      final result = await state.analyze('package:foo/a.moor');
      state.close();

      expect(
        result.errors.errors,
        contains(isA<MoorError>().having(
          (e) => e.message,
          'message',
          contains('columns may only appear in a top-level select'),
        )),
      );
    },
    timeout: Timeout.none,
  );

  test(
    'warns when nested query appear in nested query',
    () async {
      final state = TestState.withContent({
        'foo|lib/a.moor': '''
CREATE TABLE foo (
  id INT NOT NULL PRIMARY KEY,
  content VARCHAR
);

all: SELECT foo.**, LIST(SELECT *, LIST(SELECT * FROM foo) FROM foo) FROM foo;
      ''',
      });

      final result = await state.analyze('package:foo/a.moor');
      state.close();

      expect(
        result.errors.errors,
        contains(isA<MoorError>().having(
          (e) => e.message,
          'message',
          contains('query may only appear in a top-level select'),
        )),
      );
    },
    timeout: Timeout.none,
  );

  group('warns about insert column count mismatch', () {
    TestState? state;

    tearDown(() => state?.close());

    Future<void> expectError() async {
      final file = await state!.analyze('package:foo/a.moor');
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
