import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:drift/sqlite3/dialect.dart';
import 'package:test/test.dart';

import '../../generated/todos.dart';
import '../../test_utils/test_utils.dart';

void main() {
  final column = Expression<String>.custom('col');
  final binary = Expression<Uint8List>.custom('bin');

  test('json1 functions generate valid sql', () {
    expect(column.jsonArrayLength(), generates('json_array_length(col)'));
    expect(
      column.jsonArrayLength(r'$.c'),
      generates('json_array_length(col,?1)', [r'$.c']),
    );

    expect(
      column.jsonExtract(r'$.c'),
      generates('json_extract(col,?1)', [r'$.c']),
    );
  });

  group('textual', () {
    test('json', () {
      expect(column.json(), generates('json(col)'));
    });

    test('jsonb', () {
      expect(column.jsonb(), generates('jsonb(col)'));
    });

    test('jsonArrayLength', () {
      expect(column.jsonArrayLength(), generates('json_array_length(col)'));
    });

    test('jsonExtract', () {
      expect(column.jsonExtract(r'$.c'),
          generates(r'json_extract(col,?1)', [r'$.c']));
    });

    test('aggregates', () {
      expect(jsonGroupArray(column), generates('json_group_array(col)'));
      expect(
        jsonGroupArray(
          column,
          orderBy: OrderBy([OrderingTerm.desc(column)]),
          filter: column.length.isGreaterOrEqualValue(10),
        ),
        generates(
          'json_group_array(col ORDER BY col DESC) FILTER (WHERE LENGTH(col) >= ?1)',
          [10],
        ),
      );
      expect(
        jsonGroupObject({
          Variable('foo'): column,
          Variable('bar'): Literal(3),
        }),
        generates('json_group_object(?1,col,?2,3)', ['foo', 'bar']),
      );
    });

    test('jsonEach', () async {
      final db = TodoDb();
      addTearDown(db.close);

      final query = db.select(Variable.withString('{}').jsonEach());
      expect(query,
          generates('SELECT $_jsonColumns FROM json_each(?1);', [anything]));
    });

    test('jsonTree', () async {
      final db = TodoDb();
      addTearDown(db.close);

      final query = db.select(Variable.withString('{}').jsonTree());
      expect(query,
          generates('SELECT $_jsonColumns FROM json_tree(?1);', [anything]));
    });
  });

  group('binary', () {
    test('json', () {
      expect(column.jsonb().json(), generates('json(jsonb(col))'));
    });

    test('jsonArrayLength', () {
      expect(binary.jsonArrayLength(), generates('json_array_length(bin)'));
    });

    test('jsonExtract', () {
      expect(binary.jsonExtract(r'$.c'),
          generates(r'json_extract(bin,?1)', [r'$.c']));
    });

    test('aggregates', () {
      expect(jsonbGroupArray(column), generates('jsonb_group_array(col)'));
      expect(
        jsonbGroupArray(
          column,
          orderBy: OrderBy([OrderingTerm.desc(column)]),
          filter: column.length.isGreaterOrEqualValue(10),
        ),
        generates(
          'jsonb_group_array(col ORDER BY col DESC) FILTER (WHERE LENGTH(col) >= ?1)',
          [10],
        ),
      );
      expect(
        jsonbGroupObject({
          Variable('foo'): column,
          Variable('bar'): Literal(3),
        }),
        generates('jsonb_group_object(?1,col,?2,3)', ['foo', 'bar']),
      );
    });

    test('jsonEach', () async {
      final db = TodoDb();
      addTearDown(db.close);

      final query = db.select(Variable.withBlob(Uint8List(0)).jsonEach());
      expect(query,
          generates('SELECT $_jsonColumns FROM json_each(?1);', [anything]));
    });

    test('jsonTree', () async {
      final db = TodoDb();
      addTearDown(db.close);

      final query = db.select(Variable.withBlob(Uint8List(0)).jsonTree());
      expect(query,
          generates('SELECT $_jsonColumns FROM json_tree(?1);', [anything]));
    });
  });
}

const _jsonColumns =
    '"key" AS "key","value" AS "value","type" AS "type","atom" AS "atom","id" AS "id","parent" AS "parent","fullkey" AS "fullkey","path" AS "path"';
