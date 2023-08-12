import 'package:build_test/build_test.dart';
import 'package:drift/drift.dart';
import 'package:drift_dev/src/analysis/options.dart';
import 'package:drift_dev/src/writer/import_manager.dart';
import 'package:drift_dev/src/writer/queries/query_writer.dart';
import 'package:drift_dev/src/writer/writer.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../../analysis/test_utils.dart';
import '../../utils.dart';

void main() {
  Future<String> generateForQueryInDriftFile(String driftFile,
      {DriftOptions options = const DriftOptions.defaults(
        generateNamedParameters: true,
      )}) async {
    final state =
        TestBackend.inTest({'a|lib/main.drift': driftFile}, options: options);
    final file = await state.analyze('package:a/main.drift');
    state.expectNoErrors();

    final writer = Writer(
      options,
      generationOptions: GenerationOptions(
        imports: ImportManagerForPartFiles(),
      ),
    );
    QueryWriter(writer.child())
        .write(file.fileAnalysis!.resolvedQueries.values.single);

    return writer.writeGenerated();
  }

  test('generates correct parameter for nullable arrays', () async {
    final generated = await generateForQueryInDriftFile('''
        CREATE TABLE tbl (
          id INTEGER NULL
        );

        query: SELECT * FROM tbl WHERE id IN :idList;
      ''');
    expect(generated, contains('required List<int?> idList'));
  });

  test('generates correct variable order', () async {
    final generated = await generateForQueryInDriftFile('''
        CREATE TABLE tbl (
          id INTEGER NULL
        );

        query: SELECT * FROM tbl LIMIT :offset, :limit;
      ''');
    expect(
      generated,
      allOf(
        contains('SELECT * FROM tbl LIMIT ?2 OFFSET ?1'),
        contains('variables: [Variable<int>(offset), Variable<int>(limit)]'),
      ),
    );
  });

  group('nested star column', () {
    test('get renamed in SQL', () async {
      final generated = await generateForQueryInDriftFile('''
        CREATE TABLE tbl (
          id INTEGER NULL
        );

        query: SELECT t.** AS tableName FROM tbl AS t;
      ''');
      expect(
        generated,
        allOf(
          contains('SELECT"t"."id" AS "nested_0.id"'),
          contains('final TblData tableName;'),
        ),
      );
    });

    test('makes single columns nullable if from outer join', () async {
      final generated = await generateForQueryInDriftFile('''
        query: SELECT 1 AS r, joined.** FROM (SELECT 1)
            LEFT OUTER JOIN (SELECT 2 AS b) joined;
      ''');

      expect(
        generated,
        allOf(
          contains("joined: row.readNullable<int>('nested_0.b')"),
          contains('final int? joined;'),
        ),
      );
    });

    test('checks for nullable column in nested table', () async {
      final generated = await generateForQueryInDriftFile('''
        CREATE TABLE tbl (
          id INTEGER NULL
        );

        query: SELECT 1 AS a, tbl.** FROM (SELECT 1) LEFT OUTER JOIN tbl;
      ''');

      expect(
        generated,
        allOf(
          contains(
              "tbl: await tbl.mapFromRowOrNull(row, tablePrefix: 'nested_0')"),
          contains('final TblData? tbl;'),
        ),
      );
    });

    test('checks for nullable column in nested table with alias', () async {
      final generated = await generateForQueryInDriftFile('''
        CREATE TABLE tbl (
          id INTEGER NULL,
          col TEXT NOT NULL
        );

        query: SELECT 1 AS a, tbl.** FROM (SELECT 1) LEFT OUTER JOIN (SELECT id AS a, col AS b from tbl) tbl;
      ''');

      expect(
        generated,
        allOf(
          contains("tbl: row.data['nested_0.b'] == null ? null : "
              'tbl.mapFromRowWithAlias(row'),
          contains('final TblData? tbl;'),
        ),
      );
    });

    test('checks for nullable column in nested result set', () async {
      final generated = await generateForQueryInDriftFile('''
        query: SELECT 1 AS r, joined.** FROM (SELECT 1)
            LEFT OUTER JOIN (SELECT NULL AS b, 3 AS c) joined;
      ''');

      expect(
        generated,
        allOf(
          contains("joined: row.data['nested_0.c'] == null ? null : "
              "QueryNestedColumn0(b: row.readNullable<String>('nested_0.b'), "
              "c: row.read<int>('nested_0.c'), )"),
          contains('final QueryNestedColumn0? joined;'),
        ),
      );
    });
  });

  test('generates correct returning mapping', () async {
    final generated = await generateForQueryInDriftFile(
      '''
        CREATE TABLE tbl (
          id INTEGER,
          text TEXT
        );

        query: INSERT INTO tbl (id, text) VALUES(10, 'test') RETURNING id;
      ''',
      options: const DriftOptions.defaults(
        sqliteAnalysisOptions:
            // Assuming 3.35 because dso that returning works.
            SqliteAnalysisOptions(version: SqliteVersion.v3(35)),
      ),
    );
    expect(generated, contains('.toList()'));
  });

  test('generates correct code for expanded arrays', () async {
    final result = await generateForQueryInDriftFile('''
CREATE TABLE tbl (
  a TEXT,
  b TEXT,
  c TEXT
);

query: SELECT * FROM tbl WHERE a = :a AND b IN :b AND c = :c;
''');
    expect(
      result,
      allOf(
        contains(r'var $arrayStartIndex = 3;'),
        contains(r'SELECT * FROM tbl WHERE a = ?1 AND b IN ($expandedb) '
            'AND c = ?2'),
        contains(r'variables: [Variable<String>(a), Variable<String>(c), '
            r'for (var $ in b) Variable<String>($)], readsFrom: {tbl'),
      ),
    );
  });

  test(
    'sets multipleTables: true for multiple references to same table',
    () async {
      // https://github.com/simolus3/drift/issues/2425
      final generated = await generateForQueryInDriftFile(r'''
        CREATE TABLE tbl (
          id INTEGER NULL
        );

        query: SELECT tbl.id, next.id
          FROM tbl
            INNER JOIN tbl next ON next.id = tbl.id + 1
          WHERE $predicate;
      ''');
      expect(
        generated,
        allOf(
          contains(
            "final generatedpredicate = "
            r"$write(predicate(this.tbl, alias(this.tbl, 'next')), "
            r"hasMultipleTables: true, startIndex: $arrayStartIndex);",
          ),
        ),
      );
    },
  );

  group('generates correct code for nested queries', () {
    Future<void> runTest(
        DriftOptions options, List<Matcher> expectation) async {
      final result = await generateForQueryInDriftFile(
        '''
CREATE TABLE tbl (
  a TEXT,
  b TEXT,
  c TEXT
);

query:
SELECT
  parent.a,
  LIST(SELECT b, c FROM tbl WHERE a = :a OR a = parent.a AND b = :b)
FROM tbl AS parent WHERE parent.a = :a;
''',
        options: options,
      );

      for (final e in expectation) {
        expect(result, e);
      }
    }

    test('should generate correct queries with variables', () {
      return runTest(
        const DriftOptions.defaults(),
        [
          contains(
            r'SELECT parent.a, parent.a AS "\$n_0" FROM tbl AS parent WHERE parent.a = ?1',
          ),
          contains(
            r'[Variable<String>(a)]',
          ),
          contains(
            r'SELECT b, c FROM tbl WHERE a = ?1 OR a = ?2 AND b = ?3',
          ),
          contains(
            r"[Variable<String>(a), Variable<String>(row.read('\$n_0')), Variable<String>(b)]",
          ),
        ],
      );
    });

    test('should generate correct data class', () {
      return runTest(
        const DriftOptions.defaults(),
        [
          contains('QueryNestedQuery0({this.b,this.c,})'),
          contains('QueryResult({this.a,required this.nestedQuery0,})'),
        ],
      );
    });
  });

  test('generates code for custom result classes', () async {
    final result = await emulateDriftBuild(
      inputs: {
        'a|lib/a.drift': '''
import 'rows.dart';

CREATE TABLE users (
  id INTEGER NOT NULL PRIMARY KEY,
  name TEXT NOT NULL
) WITH MyUser;

foo WITH MyRow: SELECT name, otherUser.**, LIST(SELECT id FROM users) as nested
 FROM users
  INNER JOIN users otherUser ON otherUser.id = users.id + 1;
''',
        'a|lib/rows.dart': '''
class MyUser {
  final int id;
  final String name;

  MyUser({required this.id, required this.name});
}

class MyRow {
  final String name;
  final MyUser otherUser;
  final List<int> nested;

  MyRow(this.name, {required this.otherUser, required this.nested, String? unused});
}
''',
      },
      modularBuild: true,
    );

    checkOutputs(
      {
        'a|lib/a.drift.dart': decodedMatches(contains('''
  i0.Selectable<i1.MyRow> foo() {
    return customSelect(
        'SELECT name,"otherUser"."id" AS "nested_0.id", "otherUser"."name" AS "nested_0.name" FROM users INNER JOIN users AS otherUser ON otherUser.id = users.id + 1',
        variables: [],
        readsFrom: {
          users,
        }).asyncMap((i0.QueryRow row) async => i1.MyRow(
          row.read<String>('name'),
          otherUser: await users.mapFromRow(row, tablePrefix: 'nested_0'),
          nested: await customSelect('SELECT id FROM users',
              variables: [],
              readsFrom: {
                users,
              }).map((i0.QueryRow row) => row.read<int>('id')).get(),
        ));
  }
'''))
      },
      result.dartOutputs,
      result.writer,
    );
  });

  test('can map to existing row class synchronously', () async {
    // Regression test for https://github.com/simolus3/drift/issues/2282
    final result = await emulateDriftBuild(
      inputs: {
        'a|lib/row.dart': '''
class TestCustom {
  final int testId;
  final String testOneText;
  final String testTwoText;
  TestCustom({
    required this.testId,
    required this.testOneText,
    required this.testTwoText,
  });
}
''',
        'a|lib/a.drift': '''
import 'row.dart';

CREATE TABLE TestOne (
  test_id INT NOT NULL,
  test_one_text TEXT NOT NULL
);

CREATE TABLE TestTwo (
  test_id INT NOT NULL,
  test_two_text TEXT NOT NULL
);

getTest WITH TestCustom:
  SELECT
      one.*,
      two.test_two_text
  FROM TestOne one
  INNER JOIN TestTwo two
    ON one.test_id = two.test_id;
''',
      },
      modularBuild: true,
    );

    checkOutputs({
      'a|lib/a.drift.dart': decodedMatches(contains(
          '  i0.Selectable<i3.TestCustom> getTest() {\n'
          '    return customSelect(\n'
          '        \'SELECT one.*, two.test_two_text FROM TestOne AS one INNER JOIN TestTwo AS two ON one.test_id = two.test_id\',\n'
          '        variables: [],\n'
          '        readsFrom: {\n'
          '          testTwo,\n'
          '          testOne,\n'
          '        }).map((i0.QueryRow row) => i3.TestCustom(\n'
          '          testId: row.read<int>(\'test_id\'),\n'
          '          testOneText: row.read<String>(\'test_one_text\'),\n'
          '          testTwoText: row.read<String>(\'test_two_text\'),\n'
          '        ));\n'
          '  }')),
    }, result.dartOutputs, result.writer);
  });

  test('generates correct code for variables in LIST subquery', () async {
    final outputs = await emulateDriftBuild(
      inputs: {
        'a|lib/a.drift': '''
CREATE TABLE t (
  a REAL,
  b INTEGER
);

failQuery:
  SELECT
    *,
    LIST(SELECT * FROM t x WHERE x.b = b or x.b = :inB)
  FROM
    (SELECT * FROM t where a = :inA AND b = :inB);
''',
      },
      modularBuild: true,
    );

    checkOutputs({
      'a|lib/a.drift.dart': decodedMatches(contains('''
  i0.Selectable<FailQueryResult> failQuery(double? inA, int? inB) {
    return customSelect(
        'SELECT * FROM (SELECT * FROM t WHERE a = ?1 AND b = ?2)',
        variables: [
          i0.Variable<double>(inA),
          i0.Variable<int>(inB)
        ],
        readsFrom: {
          t,
        }).asyncMap((i0.QueryRow row) async => FailQueryResult(
          a: row.readNullable<double>('a'),
          b: row.readNullable<int>('b'),
          nestedQuery0: await customSelect(
              'SELECT * FROM t AS x WHERE x.b = b OR x.b = ?1',
              variables: [
                i0.Variable<int>(inB)
              ],
              readsFrom: {
                t,
              }).asyncMap(t.mapFromRow).get(),
        ));
  }
'''))
    }, outputs.dartOutputs, outputs.writer);
  });

  test('supports Dart component in HAVING', () async {
    // Regression test for https://github.com/simolus3/drift/issues/2378
    final result = await generateForQueryInDriftFile(r'''
CREATE TABLE albums (
  id INTEGER NOT NULL PRIMARY KEY,
  source_id INTEGER NOT NULL
);

CREATE TABLE songs (
  id INTEGER NOT NULL PRIMARY KEY,
  source_id INTEGER NOT NULL,
  album_id INTEGER NOT NULL,
  download_file_path TEXT
);

filterAlbums: SELECT
    albums.*,
    COUNT(songs.id) AS songs_count,
    SUM(CASE WHEN songs.download_file_path IS NOT NULL THEN 1 ELSE 0 END) AS downloaded_songs_count
  FROM albums
  LEFT JOIN songs ON albums.source_id = songs.source_id AND albums.id = songs.album_id
  WHERE $predicate
  GROUP BY albums.source_id, albums.id
  HAVING $having
  ORDER BY $order
  LIMIT $limit;
''');

    expect(
      result,
      allOf(
        contains(
          r'filterAlbums({required FilterAlbums$predicate predicate, '
          r'required FilterAlbums$having having, FilterAlbums$order? order, '
          r'required FilterAlbums$limit limit})',
        ),
        contains(r'typedef FilterAlbums$predicate = '
            'Expression<bool> Function(Albums albums, Songs songs);'),
        contains(r'typedef FilterAlbums$having = '
            'Expression<bool> Function(Albums albums, Songs songs);'),
        contains(r'typedef FilterAlbums$order = '
            'OrderBy Function(Albums albums, Songs songs);'),
        contains(r'typedef FilterAlbums$limit = '
            'Limit Function(Albums albums, Songs songs);'),
      ),
    );
  });

  test('generates invocation for named constructor in existing type', () async {
    final outputs = await emulateDriftBuild(
      inputs: {
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
      },
      modularBuild: true,
      logger: loggerThat(neverEmits(anything)),
    );

    checkOutputs({
      'a|lib/a.drift.dart': decodedMatches(contains('''
class ADrift extends i1.ModularAccessor {
  ADrift(i0.GeneratedDatabase db) : super(db);
  i0.Selectable<i2.MyRow> foo() {
    return customSelect('SELECT \\'hello world\\' AS a, 2 AS b', variables: [], readsFrom: {})
        .map((i0.QueryRow row) => i2.MyRow.foo(
              row.read<String>('a'),
              row.read<int>('b'),
            ));
  }
}'''))
    }, outputs.dartOutputs, outputs.writer);
  });

  test('creates dialect-specific query code', () async {
    final result = await generateForQueryInDriftFile(
      r'''
query (:foo AS TEXT): SELECT :foo;
''',
      options: const DriftOptions.defaults(
        dialect: DialectOptions(
            null, [SqlDialect.sqlite, SqlDialect.postgres], null),
      ),
    );

    expect(
      result,
      contains(
        'switch (executor.dialect) {'
        "SqlDialect.sqlite => 'SELECT ?1 AS _c0', "
        "SqlDialect.postgres || _  => 'SELECT \\\$1 AS _c0', "
        '}',
      ),
    );
  });
}
