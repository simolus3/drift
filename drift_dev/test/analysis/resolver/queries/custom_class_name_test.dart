import 'package:build_test/build_test.dart';
import 'package:drift_dev/src/analysis/custom_result_class.dart';
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:test/test.dart';

import '../../../utils.dart';
import '../../test_utils.dart';

void main() {
  Future<Iterable<SqlQuery>> analyzeQueries(String driftFile) async {
    final state = TestBackend.inTest({'a|lib/a.drift': driftFile});

    final result = await state.analyze('package:a/a.drift');
    return result.fileAnalysis!.resolvedQueries.values;
  }

  group('does not allow custom classes for queries', () {
    test('with a single column', () async {
      final queries = await analyzeQueries('''
        myQuery AS MyResult: SELECT 1;
      ''');

      final errors = <String>[];
      transformCustomResultClasses(queries, errors.add);

      expect(
        errors,
        contains(
          allOf(contains('myQuery'), contains('only returns one column')),
        ),
      );
    });

    test('matching a table', () async {
      final queries = await analyzeQueries('''
        CREATE TABLE demo (id INTEGER NOT NULL PRIMARY KEY);

        myQuery AS MyResult: SELECT id FROM demo;
      ''');

      final errors = <String>[];
      transformCustomResultClasses(queries, errors.add);

      expect(
        errors,
        contains(
          allOf(
            contains('myQuery'),
            contains('returns a single table data class'),
          ),
        ),
      );
    });
  });

  test('reports error for queries with different result sets', () async {
    final queries = await analyzeQueries('''
      CREATE TABLE points (
        id INTEGER NOT NULL PRIMARY KEY,
        lat REAL,
        long REAL
      );

      CREATE TABLE routes (
        "start" INTEGER REFERENCES points (id),
        "end" INTEGER REFERENCES points (id),
        PRIMARY KEY ("start", "end")
      );

      difCols1 AS DifferentColumns: SELECT id, lat FROM points;
      difCols2 AS DifferentColumns: SELECT id, long FROM points;

      difNested1 AS DifferentNested: SELECT
        start.** FROM routes INNER JOIN points start ON start.id = routes.start;
      difNested2 AS DifferentNested: SELECT
        "end".** FROM routes INNER JOIN points "end" ON "end".id = routes."end";
    ''');

    final errors = <String>[];
    transformCustomResultClasses(queries, errors.add);

    expect(
      errors,
      [
        contains('DifferentColumns'),
        contains('DifferentNested'),
      ],
    );
  });

  test('can unify queries with LIST column', () async {
    final results = await emulateDriftBuild(
      inputs: {
        'a|lib/a.drift': '''
CREATE TABLE books (
  id INT NOT NULL PRIMARY KEY,
  title TEXT NULL,
  group_name TEXT NULL
);

getTitlesWithGroup AS GroupWithTitles: SELECT group_name, LIST(SELECT title FROM books) AS titles FROM books;

getTitlesWithGroupOther AS GroupWithTitles: SELECT group_name, LIST(SELECT title FROM books WHERE title NOT LIKE 'Second%') AS titles FROM books;
''',
      },
      modularBuild: true,
      logger: loggerThat(neverEmits(anything)),
    );

    checkOutputs({
      'a|lib/a.drift.dart': decodedMatches(isA<String>().having(
        (e) => 'class GroupWithTitles'.allMatches(e),
        'contains one GroupWithTitles class',
        hasLength(1),
      )),
    }, results.dartOutputs, results.writer);
  });

  test('supports query with two list columns', () async {
    var queries = await analyzeQueries('''
CREATE TABLE books (
  id INT NOT NULL PRIMARY KEY,
  title TEXT NULL,
  group_name TEXT NULL
);

a AS TitleList: SELECT LIST(SELECT title FROM books), LIST(SELECT id, title FROM books) FROM books;
b AS TitleList: SELECT LIST(SELECT title FROM books), LIST(SELECT id, title FROM books) FROM books;
    ''');

    final errors = <String>[];
    queries = transformCustomResultClasses(queries, errors.add).values;
    expect(errors, isEmpty);

    final a = queries.first;
    final b = queries.last;

    expect(a.name, 'a');
    expect(b.name, 'b');
    expect(a.resultClassName, 'TitleList');
    expect(b.resultClassName, 'TitleList');
    expect(a.resultSet?.dontGenerateResultClass, isFalse);
    expect(b.resultSet?.dontGenerateResultClass, isTrue);

    final nestedA = a.resultSet?.nestedResults.last as NestedResultQuery;
    final nestedB = b.resultSet?.nestedResults.last as NestedResultQuery;
    expect(nestedA.query.resultSet.needsOwnClass, isTrue);
    expect(nestedB.query.resultSet.needsOwnClass, isFalse);
  });
}
