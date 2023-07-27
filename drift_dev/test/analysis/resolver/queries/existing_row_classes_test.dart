import 'package:drift_dev/src/analysis/options.dart';
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';
import 'utils.dart';

void main() {
  test('recognizes existing row classes', () async {
    final state = TestBackend.inTest({
      'a|lib/a.drift': '''
import 'a.dart';

foo WITH MyRow: SELECT 'hello world' AS a, 2 AS b;
''',
      'a|lib/a.dart': '''
class MyRow {
  final String a;
  final int b;

  MyRow(this.a, this.b);
}
''',
    });

    final uri = Uri.parse('package:a/a.drift');
    final file = await state.driver.resolveElements(uri);

    state.expectNoErrors();
    final query = file.analyzedElements.single as DefinedSqlQuery;
    expect(query.resultClassName, isNull);
    expect(query.existingDartType?.type.getDisplayString(withNullability: true),
        'MyRow');
  });

  test('can use named constructors', () async {
    final state = TestBackend.inTest({
      'a|lib/a.drift': '''
import 'a.dart';

foo WITH MyRow.foo: SELECT 'hello world' AS a, 2 AS b;
''',
      'a|lib/a.dart': '''
class MyRow {
  final String a;
  final int b;

  MyRow.foo(this.a, this.b);
}
''',
    });

    final file = await state.analyze('package:a/a.drift');

    state.expectNoErrors();
    final query = file.analyzedElements.single as DefinedSqlQuery;
    expect(query.resultClassName, isNull);
    expect(query.existingDartType?.type.getDisplayString(withNullability: true),
        'MyRow');

    final resolvedQuery = file.fileAnalysis!.resolvedQueries.values.single;
    expect(
      resolvedQuery.resultSet?.existingRowType,
      isExistingRowType(
        type: 'MyRow',
        constructorName: 'foo',
        named: isEmpty,
        positional: [
          scalarColumn('a'),
          scalarColumn('b'),
        ],
      ),
    );
  });

  test("warns if existing row classes don't exist", () async {
    final state = TestBackend.inTest({
      'a|lib/a.drift': '''
import 'a.dart';

foo WITH MyRow: SELECT 'hello world', 2;
''',
    });

    final file = await state.analyze('package:a/a.drift');
    expect(file.allErrors, [
      isDriftError(contains('are you missing an import?'))
          .withSpan('WITH MyRow')
    ]);
  });

  test('resolves existing row class', () async {
    final state = TestBackend.inTest({
      'a|lib/a.drift': '''
import 'a.dart';

foo WITH MyRow: SELECT 'hello world' AS a, 2 AS b;
''',
      'a|lib/a.dart': '''
class MyRow {
  final String a;
  final int b;

  MyRow(this.a, this.b);
}
''',
    });

    final file = await state.analyze('package:a/a.drift');
    state.expectNoErrors();

    final query = file.fileAnalysis!.resolvedQueries.values.single;
    expect(
      query.resultSet?.existingRowType,
      isExistingRowType(type: 'MyRow', named: isEmpty, positional: [
        scalarColumn('a'),
        scalarColumn('b'),
      ]),
    );
  });

  group('matches', () {
    test('single column type', () async {
      final state = TestBackend.inTest({
        'a|lib/a.drift': '''
foo WITH int: SELECT 1 AS r;
''',
      });

      final file = await state.analyze('package:a/a.drift');
      state.expectNoErrors();

      final query = file.fileAnalysis!.resolvedQueries.values.single;
      expect(
        query.resultSet?.existingRowType,
        isExistingRowType(type: 'int', singleValue: scalarColumn('r')),
      );
    });

    test('single table', () async {
      final state = TestBackend.inTest({
        'a|lib/a.drift': '''
import 'a.dart';

CREATE TABLE tbl (foo TEXT, bar INT);

foo WITH MyRow: SELECT * FROM tbl;
''',
        'a|lib/a.dart': '''
typedef MyRow = TblData;
''',
      });

      final file = await state.analyze('package:a/a.drift');
      state.expectNoErrors();

      final query = file.fileAnalysis!.resolvedQueries.values.single;
      expect(
        query.resultSet?.existingRowType,
        isExistingRowType(
          type: 'TblData',
          singleValue: isA<MatchingDriftTable>(),
        ),
      );
    });

    test('single table with custom row class', () async {
      final state = TestBackend.inTest({
        'a|lib/a.drift': '''
import 'a.dart';

CREATE TABLE tbl (foo TEXT, bar INT) WITH MyTableRow;

foo WITH MyTableRow: SELECT * FROM tbl;
''',
        'a|lib/a.dart': '''
class MyTableRow {
  final MyTableRow(String? foo, int? bar);
}
''',
      });

      final file = await state.analyze('package:a/a.drift');
      state.expectNoErrors();

      final query = file.fileAnalysis!.resolvedQueries.values.single;
      expect(
        query.resultSet?.existingRowType,
        isExistingRowType(
          type: 'MyTableRow',
          singleValue: isA<MatchingDriftTable>(),
        ),
      );
    });

    test('alternative to table class', () async {
      final state = TestBackend.inTest({
        'a|lib/a.drift': '''
import 'a.dart';

CREATE TABLE tbl (foo TEXT NOT NULL, bar INT NOT NULL) WITH MyTableRow;

foo WITH MyQueryRow: SELECT * FROM tbl;
''',
        'a|lib/a.dart': '''
class MyTableRow {
  final MyTableRow(String foo, int bar);
}

class MyQueryRow {
  final MyQueryRow(String? foo, int? bar);
}
''',
      });

      final file = await state.analyze('package:a/a.drift');
      state.expectNoErrors();

      final query = file.fileAnalysis!.resolvedQueries.values.single;
      expect(
        query.resultSet?.existingRowType,
        isExistingRowType(
          type: 'MyQueryRow',
          positional: [scalarColumn('foo'), scalarColumn('bar')],
        ),
      );
    });

    group('nested column', () {
      test('single column into field', () async {
        final state = TestBackend.inTest({
          'a|lib/a.drift': '''
import 'a.dart';

foo WITH MyQueryRow: SELECT 1 AS a, b.** FROM (SELECT 2 AS b) b;
''',
          'a|lib/a.dart': '''
class MyQueryRow {
  MyQueryRow(int a, int b);
}
''',
        });

        final file = await state.analyze('package:a/a.drift');
        state.expectNoErrors();

        final query = file.fileAnalysis!.resolvedQueries.values.single;
        expect(
          query.resultSet?.existingRowType,
          isExistingRowType(
            type: 'MyQueryRow',
            positional: [
              scalarColumn('a'),
              structedFromNested(
                isExistingRowType(
                  singleValue: scalarColumn('b'),
                ),
              ),
            ],
          ),
        );
      });

      test('single column into single-element record', () async {
        final state = TestBackend.inTest({
          'a|lib/a.drift': '''
import 'a.dart';

foo WITH MyQueryRow: SELECT 1 AS a, b.** FROM (SELECT 2 AS b) b;
''',
          'a|lib/a.dart': '''
class MyQueryRow {
  MyQueryRow(int a, (int) b);
}
''',
        });

        final file = await state.analyze('package:a/a.drift');
        state.expectNoErrors();

        final query = file.fileAnalysis!.resolvedQueries.values.single;
        expect(
          query.resultSet?.existingRowType,
          isExistingRowType(
            type: 'MyQueryRow',
            positional: [
              scalarColumn('a'),
              structedFromNested(
                isExistingRowType(
                  positional: [scalarColumn('b')],
                  isRecord: isTrue,
                ),
              ),
            ],
          ),
        );
      });

      test('custom result set', () async {
        final state = TestBackend.inTest(
          {
            'a|lib/a.drift': '''
import 'a.dart';

foo WITH MyQueryRow: SELECT 1 AS id, j.** FROM json_each('') AS j;
''',
            'a|lib/a.dart': '''
class MyQueryRow {
  MyQueryRow(int id, JsonStructure j);
}

class JsonStructure {
  JsonStructure(DriftAny key, DriftAny value, String type);
}
''',
          },
          options: const DriftOptions.defaults(
            sqliteAnalysisOptions: SqliteAnalysisOptions(
              // Make sure json_each is supported
              version: SqliteVersion.v3(38),
            ),
          ),
        );

        final file = await state.analyze('package:a/a.drift');
        state.expectNoErrors();

        final query = file.fileAnalysis!.resolvedQueries.values.single;
        expect(
          query.resultSet?.existingRowType,
          isExistingRowType(
            type: 'MyQueryRow',
            positional: [
              scalarColumn('id'),
              structedFromNested(
                isExistingRowType(
                  type: 'JsonStructure',
                ),
              ),
            ],
          ),
        );
      });

      test('table', () async {
        final state = TestBackend.inTest({
          'a|lib/a.drift': '''
import 'a.dart';

CREATE TABLE tbl (foo TEXT, bar INT);

foo WITH MyRow: SELECT 1 AS a, b.** FROM tbl
  INNER JOIN tbl b ON TRUE;
''',
          'a|lib/a.dart': '''
class MyRow {
  MyRow(int a, TblData b);
}
''',
        });

        final file = await state.analyze('package:a/a.drift');
        state.expectNoErrors();

        final query = file.fileAnalysis!.resolvedQueries.values.single;
        expect(
          query.resultSet?.existingRowType,
          isExistingRowType(
            type: 'MyRow',
            positional: [
              scalarColumn('a'),
              structedFromNested(
                isExistingRowType(
                  type: 'TblData',
                  singleValue: isA<MatchingDriftTable>(),
                ),
              ),
            ],
          ),
        );
      });

      test('table as alternative to row class', () async {
        final state = TestBackend.inTest(
          {
            'a|lib/a.drift': '''
import 'a.dart';

CREATE TABLE tbl (foo TEXT, bar INT);

foo WITH MyRow: SELECT 1 AS a, b.** FROM tbl
  INNER JOIN tbl b ON TRUE;
''',
            'a|lib/a.dart': '''
class MyRow {
  MyRow(int a, (String, int) b);
}
''',
          },
          analyzerExperiments: ['records'],
        );

        final file = await state.analyze('package:a/a.drift');
        state.expectNoErrors();

        final query = file.fileAnalysis!.resolvedQueries.values.single;
        expect(
          query.resultSet?.existingRowType,
          isExistingRowType(
            type: 'MyRow',
            positional: [
              scalarColumn('a'),
              structedFromNested(
                isExistingRowType(
                  type: '(String, int)',
                  positional: [scalarColumn('foo'), scalarColumn('bar')],
                ),
              ),
            ],
          ),
        );
      });
    });

    group('nested LIST query', () {
      test('single column type', () async {
        final state = TestBackend.inTest({
          'a|lib/a.drift': '''
import 'a.dart';

foo WITH MyQueryRow: SELECT 1 a, LIST(SELECT 2 AS b) c;
''',
          'a|lib/a.dart': '''
class MyQueryRow {
  MyQueryRow(int a, List<int> c);
}
''',
        });

        final file = await state.analyze('package:a/a.drift');
        state.expectNoErrors();

        final query = file.fileAnalysis!.resolvedQueries.values.single;
        expect(
          query.resultSet?.existingRowType,
          isExistingRowType(
            type: 'MyQueryRow',
            positional: [
              scalarColumn('a'),
              nestedListQuery(
                'c',
                isExistingRowType(
                  type: 'int',
                  singleValue: scalarColumn('b'),
                ),
              ),
            ],
          ),
        );
      });

      test('custom result set with class', () async {
        final state = TestBackend.inTest({
          'a|lib/a.drift': '''
import 'a.dart';

CREATE TABLE tbl (foo TEXT, bar INT);

foo WITH MyRow: SELECT 1 AS a, LIST(SELECT * FROM tbl) AS b FROM tbl;
''',
          'a|lib/a.dart': '''
class MyRow {
  MyRow(int a, List<MyNestedTable> b);
}

class MyNestedTable {
  MyNestedTable(String foo, int bar)
}
''',
        });

        final file = await state.analyze('package:a/a.drift');
        state.expectNoErrors();

        final query = file.fileAnalysis!.resolvedQueries.values.single;
        expect(
          query.resultSet?.existingRowType,
          isExistingRowType(
            type: 'MyRow',
            positional: [
              scalarColumn('a'),
              nestedListQuery(
                'b',
                isExistingRowType(
                  type: 'MyNestedTable',
                  positional: [scalarColumn('foo'), scalarColumn('bar')],
                ),
              ),
            ],
          ),
        );
      });

      test('custom result set with record', () async {
        final state = TestBackend.inTest(
          {
            'a|lib/a.drift': '''
import 'a.dart';

CREATE TABLE tbl (foo TEXT, bar INT);

foo WITH MyRow: SELECT 1 AS a, LIST(SELECT * FROM tbl) AS b FROM tbl;
''',
            'a|lib/a.dart': '''
class MyRow {
  MyRow(int a, List<(String, int)> b);
}
''',
          },
          analyzerExperiments: ['records'],
        );

        final file = await state.analyze('package:a/a.drift');
        state.expectNoErrors();

        final query = file.fileAnalysis!.resolvedQueries.values.single;
        expect(
          query.resultSet?.existingRowType,
          isExistingRowType(
            type: 'MyRow',
            positional: [
              scalarColumn('a'),
              nestedListQuery(
                'b',
                isExistingRowType(
                  type: '(String, int)',
                  positional: [scalarColumn('foo'), scalarColumn('bar')],
                ),
              ),
            ],
          ),
        );
      });
    });

    test('into record', () async {
      final state = TestBackend.inTest(
        {
          'a|lib/a.drift': '''
import 'a.dart';

CREATE TABLE tbl (foo TEXT, bar INT);

foo WITH MyRow: SELECT 1 AS a, LIST(SELECT * FROM tbl) AS b FROM tbl;
''',
          'a|lib/a.dart': '''
typedef MyRow = (int, List<TblData>);
''',
        },
        analyzerExperiments: ['records'],
      );

      final file = await state.analyze('package:a/a.drift');
      state.expectNoErrors();

      final query = file.fileAnalysis!.resolvedQueries.values.single;
      expect(
        query.resultSet?.existingRowType,
        isExistingRowType(
          type: '(int, List<TblData>)',
          positional: [
            scalarColumn('a'),
            nestedListQuery(
              'b',
              isExistingRowType(
                type: 'TblData',
                singleValue: isA<MatchingDriftTable>(),
              ),
            ),
          ],
        ),
      );
    });

    test(
      'default record',
      () async {
        final state = TestBackend.inTest(
          {
            'a|lib/a.drift': '''
import 'a.dart';

CREATE TABLE tbl (foo TEXT, bar INT);

foo WITH Record: SELECT 1 AS a, LIST(SELECT * FROM tbl) AS b FROM tbl;
''',
          },
          analyzerExperiments: ['records'],
        );

        final file = await state.analyze('package:a/a.drift');
        state.expectNoErrors();

        final query = file.fileAnalysis!.resolvedQueries.values.single;
        expect(
          query.resultSet?.existingRowType,
          isExistingRowType(
            type: '({int a, List<TblData> b})',
            positional: isEmpty,
            named: {
              'a': scalarColumn('a'),
              'b': nestedListQuery(
                'b',
                isExistingRowType(
                  type: 'TblData',
                  singleValue: isA<MatchingDriftTable>(),
                ),
              ),
            },
          ),
        );
      },
      skip: requireDart('3.0.0-dev'),
    );

    test('mix', () async {
      final state = TestBackend.inTest({
        'a|lib/a.drift': '''
import 'a.dart';

CREATE TABLE users (
  id INTEGER NOT NULL PRIMARY KEY,
  name TEXT NOT NULL
) WITH MyUser;

foo WITH MyRow: SELECT name, otherUser.**, LIST(SELECT id FROM users) as nested
 FROM users
  INNER JOIN users otherUser ON otherUser.id = users.id + 1;
''',
        'a|lib/a.dart': '''
class MyUser {
  final int id;
  final String name;

  MyUser({required this.id, required this.name})
}

class MyRow {
  final String name;
  final MyUser otherUser;
  final List<int> nested;

  MyRow(this.name, {required this.otherUser, required this.nested, String? unused});
}
''',
      });

      final file = await state.analyze('package:a/a.drift');
      state.expectNoErrors();

      final query = file.fileAnalysis!.resolvedQueries.values.single;
      expect(
        query.resultSet?.existingRowType,
        isExistingRowType(type: 'MyRow', positional: [
          scalarColumn('name'),
        ], named: {
          'otherUser': structedFromNested(
            isExistingRowType(
              type: 'MyUser',
              singleValue: isA<MatchingDriftTable>(),
            ),
          ),
          'nested': nestedListQuery(
            'nested',
            isExistingRowType(
              type: 'int',
              singleValue: scalarColumn('id'),
            ),
          ),
        }),
      );
    });
  });

  group('error', () {
    test('when the specified class has no default constructor', () async {
      final state = TestBackend.inTest({
        'a|lib/a.drift': '''
import 'a.dart';

foo WITH MyRow: SELECT 1;
''',
        'a|lib/a.dart': '''
class MyRow {
  MyRow.foo();
}
''',
      });

      final file = await state.analyze('package:a/a.drift');
      expect(file.allErrors, [
        isDriftError(contains('must have an unnamed constructor')),
      ]);
    });

    test('when the desired constructor does not exist', () async {
      final state = TestBackend.inTest({
        'a|lib/a.drift': '''
import 'a.dart';

foo WITH MyRow.bar: SELECT 1;
''',
        'a|lib/a.dart': '''
class MyRow {
  MyRow.foo();
}
''',
      });

      final file = await state.analyze('package:a/a.drift');
      expect(file.allErrors, [
        isDriftError(contains('`bar`')),
      ]);
    });

    test('when there is a parameter with no matching column', () async {
      final state = TestBackend.inTest({
        'a|lib/a.drift': '''
import 'a.dart';

foo WITH MyRow: SELECT 1 AS b;
''',
        'a|lib/a.dart': '''
class MyRow {
  MyRow(int a);
}
''',
      });

      final file = await state.analyze('package:a/a.drift');
      expect(file.allErrors, [
        isDriftError(contains('parameter a has no matching column')),
      ]);
    });

    test('when a record has too many positional fields', () async {
      final state = TestBackend.inTest(
        {
          'a|lib/a.drift': '''
import 'a.dart';

foo WITH MyRow: SELECT 1 AS b;
''',
          'a|lib/a.dart': '''
typedef MyRow = (int, String, DateTime);
''',
        },
        analyzerExperiments: ['records'],
      );

      final file = await state.analyze('package:a/a.drift');
      expect(file.allErrors, [
        isDriftError(
            contains('has 3 positional fields, but there are only 1 columns.')),
      ]);
    });

    test('when a record has an unmatched named field', () async {
      final state = TestBackend.inTest(
        {
          'a|lib/a.drift': '''
import 'a.dart';

foo WITH MyRow: SELECT 1 AS b, '2' as c;
''',
          'a|lib/a.dart': '''
typedef MyRow = (int, {String d});
''',
        },
        analyzerExperiments: ['records'],
      );

      final file = await state.analyze('package:a/a.drift');
      expect(file.allErrors, [
        isDriftError(contains('field d has no matching column')),
      ]);
    });

    test('when there is a type mismatch on a scalar column', () async {
      final state = TestBackend.inTest({
        'a|lib/a.drift': '''
import 'a.dart';

foo WITH MyRow: SELECT 1 AS a;
''',
        'a|lib/a.dart': '''
class MyRow {
  MyRow(String a);
}
''',
      });

      final file = await state.analyze('package:a/a.drift');
      expect(file.allErrors, [
        isDriftError(contains('Parameter must accept int')),
      ]);
    });

    test('when a list column is not a list', () async {
      final state = TestBackend.inTest({
        'a|lib/a.drift': '''
import 'a.dart';

CREATE TABLE tbl (bar INT, baz TEXT);

foo WITH MyRow: SELECT LIST(SELECT * FROM tbl) AS a;
''',
        'a|lib/a.dart': '''
class MyRow {
  MyRow(String a);
}
''',
      });

      final file = await state.analyze('package:a/a.drift');
      expect(file.allErrors, [
        isDriftError(contains('a must be a List')),
      ]);
    });

    test(
      'when there is a type mismatch on a nested scalar column',
      () async {
        final state = TestBackend.inTest({
          'a|lib/a.drift': '''
import 'a.dart';

CREATE TABLE tbl (bar INT, baz TEXT);

foo WITH MyRow: SELECT LIST(SELECT bar FROM tbl) AS a;
''',
          'a|lib/a.dart': '''
class MyRow {
  MyRow(List<String> a);
}
''',
        });

        final file = await state.analyze('package:a/a.drift');
        expect(file.allErrors, [
          isDriftError(
              'For Parameter a: The class to use as an existing row type must '
              'have an unnamed constructor.'),
        ]);
      },
    );
  });
}
