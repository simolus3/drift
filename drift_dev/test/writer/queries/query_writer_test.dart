import 'package:drift_dev/src/analysis/options.dart';
import 'package:drift_dev/src/writer/import_manager.dart';
import 'package:drift_dev/src/writer/queries/query_writer.dart';
import 'package:drift_dev/src/writer/writer.dart';
import 'package:test/test.dart';

import '../../analysis/test_utils.dart';

void main() {
  Future<String> generateForQueryInDriftFile(String driftFile,
      {DriftOptions options = const DriftOptions.defaults()}) async {
    final state =
        TestBackend.inTest({'a|lib/main.drift': driftFile}, options: options);
    final file = await state.analyze('package:a/main.drift');

    final writer = Writer(
      const DriftOptions.defaults(generateNamedParameters: true),
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

  test('generates correct name for renamed nested star columns', () async {
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

  test('generates correct returning mapping', () async {
    final generated = await generateForQueryInDriftFile('''
        CREATE TABLE tbl (
          id INTEGER,
          text TEXT
        );

        query: INSERT INTO tbl (id, text) VALUES(10, 'test') RETURNING id;
      ''');
    expect(generated, contains('.toList()'));
  });

  group('generates correct code for expanded arrays', () {
    Future<void> runTest(DriftOptions options, Matcher expectation) async {
      final result = await generateForQueryInDriftFile('''
CREATE TABLE tbl (
  a TEXT,
  b TEXT,
  c TEXT
);

query: SELECT * FROM tbl WHERE a = :a AND b IN :b AND c = :c;
''', options: options);
      expect(result, expectation);
    }

    test('with the new query generator', () {
      return runTest(
        const DriftOptions.defaults(),
        allOf(
          contains(r'var $arrayStartIndex = 3;'),
          contains(r'SELECT * FROM tbl WHERE a = ?1 AND b IN ($expandedb) '
              'AND c = ?2'),
          contains(r'variables: [Variable<String>(a), Variable<String>(c), '
              r'for (var $ in b) Variable<String>($)], readsFrom: {tbl'),
        ),
      );
    });
  });

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
}
