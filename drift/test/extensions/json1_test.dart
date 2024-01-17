import 'package:drift/drift.dart';
import 'package:drift/extensions/json1.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils/test_utils.dart';

void main() {
  const column = CustomExpression<String>('col');
  const binary = CustomExpression<Uint8List>('bin');

  test('json1 functions generate valid sql', () {
    expect(column.jsonArrayLength(), generates('json_array_length(col)'));
    expect(
      column.jsonArrayLength(r'$.c'),
      generates('json_array_length(col, ?)', [r'$.c']),
    );

    expect(
      column.jsonExtract(r'$.c'),
      generates('json_extract(col, ?)', [r'$.c']),
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
          generates(r'json_extract(col, ?)', [r'$.c']));
    });

    test('jsonEach', () async {
      final db = TodoDb();
      addTearDown(db.close);

      final query = db.select(Variable.withString('{}').jsonEach(db));
      expect(query, generates('SELECT * FROM json_each(?)', [anything]));
    });

    test('jsonTree', () async {
      final db = TodoDb();
      addTearDown(db.close);

      final query = db.select(Variable.withString('{}').jsonTree(db));
      expect(query, generates('SELECT * FROM json_tree(?)', [anything]));
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
          generates(r'json_extract(bin, ?)', [r'$.c']));
    });

    test('jsonEach', () async {
      final db = TodoDb();
      addTearDown(db.close);

      final query = db.select(Variable.withBlob(Uint8List(0)).jsonEach(db));
      expect(query, generates('SELECT * FROM json_each(?)', [anything]));
    });

    test('jsonTree', () async {
      final db = TodoDb();
      addTearDown(db.close);

      final query = db.select(Variable.withBlob(Uint8List(0)).jsonTree(db));
      expect(query, generates('SELECT * FROM json_tree(?)', [anything]));
    });
  });
}
