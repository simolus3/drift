import 'package:drift_dev/src/analysis/driver/state.dart';
import 'package:drift_dev/src/analyzer/options.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  test('warns when a result column is unresolved', () async {
    final result = await TestBackend.analyzeSingle('a: SELECT ?;');

    expect(result.allErrors,
        [isDriftError(contains('unknown type')).withSpan('?')]);
  });

  test('warns for skipped variable index', () async {
    final result = await TestBackend.analyzeSingle('''
q1(?2 AS TEXT): SELECT ?2;
q2: SELECT ?1 = ?3;
q3: SELECT ?1 = ?3 OR ?2;
''');

    expect(result.allErrors, [
      isDriftError(
              'Illegal variable index 2 because no variable at index 1 exists.')
          .withSpan('?2'),
      isDriftError(
              'Illegal variable index 3 because no variable at index 2 exists.')
          .withSpan('?3'),
    ]);
  });

  test('warns for illegal variable after array or placeholder', () async {
    final result = await TestBackend.analyzeSingle(r'''
CREATE TABLE t (i INTEGER PRIMARY KEY);

q1: SELECT * FROM t WHERE i IN ? OR i == ?2;
ok1: SELECT * FROM t WHERE i == ?1 OR i IN ?;
ok2: SELECT * FROM t WHERE i IN ? OR i = ?;

q2: SELECT * FROM t WHERE $pred OR ?1;
ok3: SELECT * FROM t WHERE i == ?1 OR $pred;
ok4: SELECT * FROM t WHERE $pred OR i = ?;

ok5: SELECT * FROM t WHERE $pred OR i IN ?;
''');

    final message = contains('Cannot have have a variable with an index lower');

    expect(result.allErrors, [
      isDriftError(message).withSpan('?2'),
      isDriftError(message).withSpan('?1'),
    ]);
  });

  test('warns about indexed array variable', () async {
    final result = await TestBackend.analyzeSingle(r'''
CREATE TABLE t (i INTEGER PRIMARY KEY);

q: SELECT * FROM t WHERE i IN ?1;
''');

    expect(
      result.allErrors,
      [
        isDriftError('Cannot use an array variable with an explicit index')
            .withSpan('?1'),
      ],
    );
  });

  test('no warning for Dart placeholder in column', () async {
    final result =
        await TestBackend.analyzeSingle(r"a: SELECT 'string' = $expr;");

    expect(result.allErrors, isEmpty);
  });

  test('warns when nested results refer to table-valued functions', () async {
    final result = await TestBackend.analyzeSingle(
      "a: SELECT json_each.** FROM json_each('');",
      options: DriftOptions.defaults(modules: [SqlModule.json1]),
    );

    expect(
      result.allErrors,
      [
        isDriftError(
                contains('Nested star columns must refer to a table directly.'))
            .withSpan('json_each.**')
      ],
    );
  });

  test('warns about default values outside of expressions', () async {
    final state = TestBackend.inTest({
      'foo|lib/a.drift': r'''
CREATE TABLE foo (
  id INT NOT NULL PRIMARY KEY,
  content VARCHAR
);

all ($limit = 3): SELECT * FROM foo LIMIT $limit;
      ''',
    });

    final result = await state.analyze('package:foo/a.drift');

    expect(
      result.allErrors,
      contains(isDriftError(contains('only supported for expressions'))),
    );
  });

  test('warns when placeholder are used in insert with columns', () async {
    final state = TestBackend.inTest({
      'foo|lib/a.drift': r'''
CREATE TABLE foo (
  id INT NOT NULL PRIMARY KEY,
  content VARCHAR
);

in: INSERT INTO foo (id) $placeholder;
      ''',
    });

    final result = await state.analyze('package:foo/a.drift');

    expect(
      result.allErrors,
      contains(isDriftError(contains("Dart placeholders can't be used here"))),
    );
  });

  test(
    'warns when nested results appear in compound statements',
    () async {
      final state = TestBackend.inTest({
        'foo|lib/a.drift': '''
CREATE TABLE foo (
  id INT NOT NULL PRIMARY KEY,
  content VARCHAR
);

all: SELECT foo.** FROM foo UNION ALL SELECT foo.** FROM foo;
      ''',
      });

      final result = await state.analyze('package:foo/a.drift');

      expect(
        result.allErrors,
        contains(isDriftError(
            contains('columns may only appear in a top-level select'))),
      );
    },
  );

  test(
    'warns when nested query appear in nested query',
    () async {
      final state = TestBackend.inTest({
        'foo|lib/a.drift': '''
CREATE TABLE foo (
  id INT NOT NULL PRIMARY KEY,
  content VARCHAR
);

all: SELECT foo.**, LIST(SELECT *, LIST(SELECT * FROM foo) FROM foo) FROM foo;
      ''',
      });

      final result = await state.analyze('package:foo/a.drift');

      expect(
        result.allErrors,
        contains(isDriftError(
            contains('query may only appear in a top-level select'))),
      );
    },
  );

  group('warns about insert column count mismatch', () {
    TestBackend? state;

    Future<void> expectError() async {
      final file = await state!.analyze('package:foo/a.drift');
      expect(
        file.allErrors,
        contains(isDriftError('Expected tuple to have 2 values')),
      );
    }

    test('in top-level queries', () async {
      state = TestBackend.inTest({
        'foo|lib/a.drift': '''
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
      state = TestBackend.inTest({
        'foo|lib/a.drift': '''
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
      state = TestBackend.inTest({
        'foo|lib/a.drift': '''
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

  group('warning about comparing textual date times', () {
    Future<FileState> handle(String sql, {bool dateTimesAreText = true}) async {
      final state = await TestBackend.analyzeSingle(
        options:
            DriftOptions.defaults(storeDateTimeValuesAsText: dateTimesAreText),
        '''
CREATE TABLE t (
  a DATETIME, b DATETIME, c DATETIME
);

q: $sql;
''',
      );

      return state;
    }

    test('for BETWEEN', () async {
      final state = await handle('SELECT a BETWEEN b AND c FROM t');

      expect(
        state.allErrors,
        contains(isDriftError(
          contains('This compares two date time values lexicographically'),
        )),
      );
    });

    test('for equality', () async {
      for (final operator in ['=', '==', '<>', '!=']) {
        final state = await handle('SELECT a $operator b FROM t');
        expect(
          state.allErrors,
          contains(
            isDriftError(
              contains(
                'Semantically equivalent date time values may be formatted '
                'differently',
              ),
            ).withSpan(operator),
          ),
        );
      }
    });

    test('for comparisons', () async {
      for (final operator in ['<', '<=', '>=', '>']) {
        final state = await handle('SELECT a $operator b FROM t');
        expect(
          state.allErrors,
          contains(
            isDriftError(
              contains(
                'This compares two date time values lexicographically',
              ),
            ).withSpan(operator),
          ),
        );
      }
    });

    test('does not trigger for unix timestamps', () async {
      expect(
          (await handle('SELECT a = b FROM t', dateTimesAreText: false))
              .allErrors,
          isEmpty);
      expect(
          (await handle('SELECT a BETWEEN b AND c FROM t',
                  dateTimesAreText: false))
              .allErrors,
          isEmpty);
      expect(
          (await handle('SELECT a <= c FROM t', dateTimesAreText: false))
              .allErrors,
          isEmpty);
    });
  });
}
