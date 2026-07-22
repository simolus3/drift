import 'package:drift3/drift.dart';
import 'package:drift_sqlite/drift_sqlite.dart';
import 'package:test/test.dart';

import '../../generated/todos.dart';
import '../../test_utils.dart';

void main() {
  final column = Expression<String>.custom('col');
  final jsonColumn = Expression<DatabaseJson>.custom('json');

  const dialectWithText = SqliteDialect.withOptions(
    options: SqliteOptions(useBinaryJsonRepresentation: false),
  );
  const dialectWithJsonb = SqliteDialect.withOptions(
    options: SqliteOptions(useBinaryJsonRepresentation: true),
  );

  test('uses underlying type', () {
    expect(
      column.cast<DatabaseJson>(),
      generatesWithDialect('CAST(col AS TEXT)', dialect: dialectWithText),
    );
    expect(
      column.cast<DatabaseJson>(),
      generatesWithDialect('CAST(col AS BLOB)', dialect: dialectWithJsonb),
    );
  });

  test('text to json', () {
    expect(
      JsonExpression.parse(column),
      generatesWithDialect('json(col)', dialect: dialectWithText),
    );
    expect(
      JsonExpression.parse(column),
      generatesWithDialect('jsonb(col)', dialect: dialectWithJsonb),
    );
  });

  for (final (name, dialect, isBinary) in const [
    ('text', dialectWithText, false),
    ('binary', dialectWithJsonb, true),
  ]) {
    group(name, () {
      test('array length', () {
        expect(
          jsonColumn.jsonArrayLength(),
          generatesWithDialect('json_array_length(json)', dialect: dialect),
        );
        expect(
          jsonColumn.jsonArrayLength(r'$.c'),
          generatesWithDialect(
            'json_array_length(json,?1)',
            dialect: dialect,
            variables: [r'$.c'],
          ),
        );
      });

      test('jsonExtract', () {
        expect(
          jsonColumn.jsonExtract(r'$.c'),
          generatesWithDialect(
            isBinary ? r'jsonb_extract(json,?1)' : r'json_extract(json,?1)',
            variables: [r'$.c'],
            dialect: dialect,
          ),
        );
      });

      test('aggregates', () {
        final arrayFunction = isBinary
            ? 'jsonb_group_array'
            : 'json_group_array';
        final objectFunction = isBinary
            ? 'jsonb_group_object'
            : 'json_group_object';

        expect(
          jsonGroupArray(column),
          generatesWithDialect('$arrayFunction(col)', dialect: dialect),
        );
        expect(
          jsonGroupArray(
            column,
            orderBy: OrderBy([OrderingTerm.desc(column)]),
            filter: column.length.isGreaterOrEqualValue(10),
          ),
          generatesWithDialect(
            '$arrayFunction(col ORDER BY col DESC) FILTER (WHERE LENGTH(col) >= ?1)',
            variables: [10],
            dialect: dialect,
          ),
        );
        expect(
          jsonGroupObject({
            Variable('foo'): column,
            Variable('bar'): Literal(3),
          }),
          generatesWithDialect(
            '$objectFunction(?1,col,?2,3)',
            variables: ['foo', 'bar'],
            dialect: dialect,
          ),
        );
      });
    });

    test('jsonEach', () async {
      final db = TodoDb();
      addTearDown(db.close);

      final query = db.select(
        Variable<DatabaseJson>(DatabaseJson({'foo': 'bar'})).jsonEach(),
      );
      expect(
        query,
        generates(
          'SELECT "key","value","type","atom","id","parent","fullkey","path" FROM json_each(?1);',
          [anything],
        ),
      );
    });

    test('jsonTree', () async {
      final db = TodoDb();
      addTearDown(db.close);

      final query = db.select(
        Variable<DatabaseJson>(DatabaseJson({'foo': 'bar'})).jsonTree(),
      );
      expect(
        query,
        generates(
          'SELECT "key","value","type","atom","id","parent","fullkey","path" FROM json_tree(?1);',
          [anything],
        ),
      );
    });
  }
}
