import 'package:moor_generator/moor_generator.dart';
import 'package:moor_generator/src/analyzer/errors.dart';
import 'package:moor_generator/src/analyzer/runner/results.dart';
import 'package:moor_generator/src/analyzer/sql_queries/custom_result_class.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  Future<BaseMoorAccessor> _analyzeQueries(String moorFile) async {
    final state = TestState.withContent({'foo|lib/a.moor': moorFile});

    final result = await state.analyze('package:foo/a.moor');
    state.close();
    final queries = (result.currentResult as ParsedMoorFile).resolvedQueries;

    return Database(declaration: DatabaseOrDaoDeclaration(null, result))
      ..queries = queries;
  }

  group('does not allow custom classes for queries', () {
    test('with a single column', () async {
      final queries = await _analyzeQueries('''
        myQuery AS MyResult: SELECT 1;
      ''');

      final errors = ErrorSink();
      CustomResultClassTransformer(queries).transform(errors);

      expect(
        errors.errors.map((e) => e.message),
        contains(
          allOf(contains('myQuery'), contains('only returns one column')),
        ),
      );
    });

    test('matching a table', () async {
      final queries = await _analyzeQueries('''
        CREATE TABLE demo (id INTEGER NOT NULL PRIMARY KEY);
      
        myQuery AS MyResult: SELECT id FROM demo;
      ''');

      final errors = ErrorSink();
      CustomResultClassTransformer(queries).transform(errors);

      expect(
        errors.errors.map((e) => e.message),
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
    final queries = await _analyzeQueries('''
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

    final errors = ErrorSink();
    CustomResultClassTransformer(queries).transform(errors);

    expect(
      errors.errors.map((e) => e.message),
      [
        contains('DifferentColumns'),
        contains('DifferentNested'),
      ],
    );
  });
}
