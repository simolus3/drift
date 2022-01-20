//@dart=2.9
import 'package:drift_dev/src/analyzer/sql_queries/type_mapping.dart';
import 'package:drift_dev/src/model/sql_query.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

final _idColumn = TableColumn('id', const ResolvedType(type: BasicType.int));
final _titleColumn =
    TableColumn('title', const ResolvedType(type: BasicType.text));
final Table table =
    Table(name: 'todos', resolvedColumns: [_idColumn, _titleColumn]);

void main() {
  final engine = SqlEngine(EngineOptions(useMoorExtensions: true));
  final mapper = TypeMapper();

  test('extracts variables and sorts them by index', () {
    final result = engine.analyze(
        'SELECT * FROM todos WHERE title = ?2 OR id IN ? OR title = ?1');

    final elements =
        mapper.extractElements(result, result.root).cast<FoundVariable>();

    expect(elements.map((v) => v.index), [1, 2, 3]);
  });

  test('throws when an array with an explicit index is used', () {
    final result = engine.analyze('SELECT 1 WHERE 1 IN ?1');

    expect(
        () => mapper.extractElements(result, result.root), throwsArgumentError);
  });

  test(
    'throws when an explicitly index var with higher index appears after array',
    () {
      final result = engine.analyze('SELECT 1 WHERE 1 IN ? OR 2 = ?2');
      expect(() => mapper.extractElements(result, result.root),
          throwsArgumentError);
    },
  );

  test('extracts variables but excludes nested queries', () {
    final result = engine.analyze(
      'SELECT *, LIST(SELECT * FROM todos WHERE title = ?3)'
      'FROM todos WHERE title = ?2 OR id IN ? OR title = ?1',
    );

    final elements =
        mapper.extractElements(result, result.root).cast<FoundVariable>();

    expect(elements.map((v) => v.index), [1, 2, 3]);
  });

  test('extracts variables from nested query', () {
    final result = engine.analyze(
      'SELECT *, LIST(SELECT * FROM todos WHERE title = ?1)'
      'FROM todos WHERE title = ?2 OR id IN ? OR title = ?1',
    );

    final root =
        ((result.root as SelectStatement).columns[1] as NestedQueryColumn)
            .select;

    final elements = mapper.extractElements(result, root).cast<FoundVariable>();

    expect(elements.map((v) => v.index), [1]);
  });
}
