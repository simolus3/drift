import 'package:drift_dev/src/analysis/custom_result_class.dart';
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

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
}
