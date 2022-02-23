import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../data.dart';

// Cases copied from the regular type inference algorithm test
const Map<String, ResolvedType?> _types = {
  'SELECT * FROM demo WHERE id = ?': ResolvedType(type: BasicType.int),
  'SELECT * FROM demo WHERE content = ?': ResolvedType(type: BasicType.text),
  'SELECT * FROM demo WHERE content == ?': ResolvedType(type: BasicType.text),
  'SELECT * FROM demo LIMIT ?': ResolvedType(type: BasicType.int),
  'SELECT 1 FROM demo GROUP BY id HAVING COUNT(*) = ?':
      ResolvedType(type: BasicType.int),
  'SELECT 1 FROM demo WHERE id BETWEEN 3 AND ?':
      ResolvedType(type: BasicType.int),
  'UPDATE demo SET content = ? WHERE id = 3':
      ResolvedType(type: BasicType.text),
  'SELECT * FROM demo WHERE content LIKE ?': ResolvedType(type: BasicType.text),
  "SELECT * FROM demo WHERE content LIKE '%e' ESCAPE ?":
      ResolvedType(type: BasicType.text),
  'SELECT * FROM demo WHERE content IN ?':
      ResolvedType(type: BasicType.text, isArray: true),
  'SELECT * FROM demo WHERE content IN (?)':
      ResolvedType(type: BasicType.text, isArray: false),
  'SELECT * FROM demo JOIN tbl ON demo.id = tbl.id WHERE date = ?':
      ResolvedType(type: BasicType.int, hint: IsDateTime()),
  'SELECT row_number() OVER (RANGE ? PRECEDING)':
      ResolvedType(type: BasicType.int),
  'SELECT ?;': null,
  'SELECT CAST(3 AS TEXT) = ?': ResolvedType(type: BasicType.text),
  'SELECT (3 * 4) = ?': ResolvedType(type: BasicType.int),
  'SELECT (3 / 4) = ?': ResolvedType(type: BasicType.int),
  'SELECT (3 / 4.) = ?': ResolvedType(type: BasicType.real),
  'SELECT NULLIF(3, 3) IS ?': ResolvedType(type: BasicType.int, nullable: true),
  'SELECT CURRENT_TIMESTAMP = ?': ResolvedType(type: BasicType.text),
  "SELECT COALESCE(NULL, 'foo') = ?": ResolvedType(type: BasicType.text),
  'SELECT NULLIF(3, 4) = ?': ResolvedType(type: BasicType.int, nullable: true),
  "SELECT 'foo' COLLATE NOCASE = ?": ResolvedType(type: BasicType.text),
  'SELECT ? COLLATE BINARY': ResolvedType(type: BasicType.text),
  "SELECT ('foo' + 'bar') = ?": ResolvedType(type: BasicType.int),
  'INSERT INTO demo DEFAULT VALUES ON CONFLICT (id) WHERE ? DO NOTHING':
      ResolvedType.bool(),
  'INSERT INTO demo DEFAULT VALUES ON CONFLICT DO UPDATE SET id = id WHERE ?':
      ResolvedType.bool(),
  'SELECT GROUP_CONCAT(content) = ? FROM demo;':
      ResolvedType(type: BasicType.text, nullable: true),
  "SELECT '' -> '' = ?": ResolvedType(type: BasicType.text, nullable: true),
  "SELECT '' ->> '' = ?": null,
  "SELECT ? -> 'a' = 'b'": ResolvedType(type: BasicType.text, nullable: false),
  "SELECT ? ->> 'a' = 'b'": ResolvedType(type: BasicType.text, nullable: false),
  "SELECT 'a' -> ? = 'b'": ResolvedType(type: BasicType.text, nullable: false),
  "SELECT 'a' ->> ? = 'b'": ResolvedType(type: BasicType.text, nullable: false),
};

SqlEngine _spawnEngine() {
  return SqlEngine()
    ..registerTable(demoTable)
    ..registerTable(anotherTable);
}

void main() {
  group('miscellaneous type inference cases', () {
    _types.forEach((sql, expected) {
      test('for $sql', () {
        final engine = _spawnEngine();
        final content = engine.analyze(sql);

        final variable = content.root.allDescendants
            .firstWhere((node) => node is Variable) as Typeable;

        expect(content.typeOf(variable).type, equals(expected));
      });
    });
  });

  test('resolves all expressions in CTE', () {
    final engine = _spawnEngine();
    final content = engine.analyze('''
WITH RECURSIVE
  cnt(x) AS (
    SELECT 1
      UNION ALL
      SELECT x+1 FROM cnt
      LIMIT 1000000
  )
  SELECT x FROM cnt;    
    ''');

    final expressions = content.root.allDescendants.whereType<Expression>();
    expect(
      expressions.map((e) => content.typeOf(e).type),
      everyElement(isNotNull),
    );
  });
}
