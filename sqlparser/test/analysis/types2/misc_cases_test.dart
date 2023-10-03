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
  'SELECT * FROM demo WHERE content IN ? OR content = ?2':
      ResolvedType(type: BasicType.text, isArray: true),
  'SELECT * FROM demo WHERE content IN (?)':
      ResolvedType(type: BasicType.text, isArray: false),
  'SELECT * FROM demo JOIN tbl ON demo.id = tbl.id WHERE date = ?':
      ResolvedType(type: BasicType.int, hints: [IsDateTime()]),
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
  'SELECT MAX(id, ?) FROM demo': ResolvedType(type: BasicType.int),
  'SELECT SUM(id = 2) = ? FROM demo': ResolvedType(type: BasicType.int),
  "SELECT unixepoch('now') = ?":
      ResolvedType(type: BasicType.int, nullable: true, hints: [IsDateTime()]),
  "SELECT datetime('now') = ?":
      ResolvedType(type: BasicType.text, nullable: true, hints: [IsDateTime()]),
  'SELECT CAST(NULLIF(1, 2) AS INTEGER) = ?': ResolvedType(
    type: BasicType.int,
    nullable: true,
  ),
  "SELECT unhex('ab') = ?": ResolvedType(type: BasicType.blob, nullable: true),
  'SELECT unhex(?)': ResolvedType(type: BasicType.text),
  'SELECT 1 GROUP BY 1 HAVING ? ': ResolvedType.bool(),
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

  test('concatenation is nullable when any part is', () {
    // https://github.com/simolus3/drift/issues/1719

    final engine = SqlEngine()
      ..registerTableFromSql('CREATE TABLE foobar (foo TEXT, bar TEXT);');

    final content =
        engine.analyze("SELECT foo, bar, foo || ' ' || bar FROM foobar;");

    final columns = (content.root as SelectStatement).resolvedColumns!;
    expect(
        columns.map(content.typeOf),
        everyElement(isA<ResolveResult>()
            .having((e) => e.type?.nullable, 'type.nullable', isTrue)));
  });

  test('can extract custom type', () {
    final engine = SqlEngine();

    final content = engine.analyze(
      'SELECT CAST(1 AS MyCustomType)',
      stmtOptions: AnalyzeStatementOptions(
        resolveTypeFromText: expectAsync1(
          (typeName) {
            expect(typeName, 'MyCustomType');
            return ResolvedType.bool();
          },
        ),
      ),
    );

    final select = content.root as SelectStatement;
    final column = select.resolvedColumns!.single;

    expect(content.typeOf(column).type, ResolvedType.bool());
  });
}
