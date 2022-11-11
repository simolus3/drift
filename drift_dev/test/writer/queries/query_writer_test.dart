import 'package:drift_dev/src/analysis/options.dart';
import 'package:drift_dev/src/analyzer/runner/results.dart';
import 'package:drift_dev/writer.dart';
import 'package:test/test.dart';

import '../../analyzer/utils.dart';

void main() {
  test('generates correct parameter for nullable arrays', () async {
    final state = TestState.withContent({
      'a|lib/main.moor': '''
        CREATE TABLE tbl (
          id INTEGER NULL
        );

        query: SELECT * FROM tbl WHERE id IN :idList;
      ''',
    });
    addTearDown(state.close);

    final file = await state.analyze('package:a/main.moor');
    final fileState = file.currentResult as ParsedDriftFile;

    final writer =
        Writer(const DriftOptions.defaults(generateNamedParameters: true));
    QueryWriter(writer.child()).write(fileState.resolvedQueries!.single);

    expect(writer.writeGenerated(), contains('required List<int?> idList'));
  });

  test('generates correct variable order', () async {
    final state = TestState.withContent({
      'a|lib/main.moor': '''
        CREATE TABLE tbl (
          id INTEGER NULL
        );

        query: SELECT * FROM tbl LIMIT :offset, :limit;
      ''',
    });
    addTearDown(state.close);

    final file = await state.analyze('package:a/main.moor');
    final fileState = file.currentResult as ParsedDriftFile;

    final writer = Writer(const DriftOptions.defaults());
    QueryWriter(writer.child()).write(fileState.resolvedQueries!.single);

    expect(
      writer.writeGenerated(),
      allOf(
        contains('SELECT * FROM tbl LIMIT ?2 OFFSET ?1'),
        contains('variables: [Variable<int>(offset), Variable<int>(limit)]'),
      ),
    );
  });

  test('generates correct name for renamed nested star columns', () async {
    final state = TestState.withContent({
      'a|lib/main.moor': '''
        CREATE TABLE tbl (
          id INTEGER NULL
        );

        query: SELECT t.** AS tableName FROM tbl AS t;
      ''',
    });
    addTearDown(state.close);

    final file = await state.analyze('package:a/main.moor');
    final fileState = file.currentResult as ParsedDriftFile;

    final writer = Writer(const DriftOptions.defaults());
    QueryWriter(writer.child()).write(fileState.resolvedQueries!.single);

    expect(
      writer.writeGenerated(),
      allOf(
        contains('SELECT"t"."id" AS "nested_0.id"'),
        contains('final TblData tableName;'),
      ),
    );
  });

  test('generates correct returning mapping', () async {
    final state = TestState.withContent({
      'a|lib/main.moor': '''
        CREATE TABLE tbl (
          id INTEGER,
          text TEXT
        );

        query: INSERT INTO tbl (id, text) VALUES(10, "test") RETURNING id;
      ''',
    });
    addTearDown(state.close);

    final file = await state.analyze('package:a/main.moor');
    final fileState = file.currentResult as ParsedDriftFile;

    final writer = Writer(const DriftOptions.defaults());
    QueryWriter(writer.child()).write(fileState.resolvedQueries!.single);

    expect(writer.writeGenerated(), contains('.toList()'));
  });

  group('generates correct code for expanded arrays', () {
    late TestState state;

    setUp(() {
      state = TestState.withContent({
        'a|lib/main.moor': '''
          CREATE TABLE tbl (
            a TEXT,
            b TEXT,
            c TEXT
          );

          query: SELECT * FROM tbl WHERE a = :a AND b IN :b AND c = :c;
        ''',
      });
    });

    tearDown(() => state.close());

    Future<void> runTest(DriftOptions options, Matcher expectation) async {
      final file = await state.analyze('package:a/main.moor');
      final fileState = file.currentResult as ParsedDriftFile;

      expect(file.errors.errors, isEmpty);

      final writer = Writer(options);
      QueryWriter(writer.child()).write(fileState.resolvedQueries!.single);

      expect(writer.writeGenerated(), expectation);
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
    late TestState state;

    setUp(() {
      state = TestState.withContent({
        'a|lib/main.moor': '''
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
      });
    });

    tearDown(() => state.close());

    Future<void> runTest(
        DriftOptions options, List<Matcher> expectation) async {
      final file = await state.analyze('package:a/main.moor');
      final fileState = file.currentResult as ParsedDriftFile;

      expect(file.errors.errors, isEmpty);

      final writer = Writer(options);
      QueryWriter(writer.child()).write(fileState.resolvedQueries!.single);

      final result = writer.writeGenerated();
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
