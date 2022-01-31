import 'package:drift_dev/src/analyzer/options.dart';
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
    }, enableAnalyzer: false);
    addTearDown(state.close);

    final file = await state.analyze('package:a/main.moor');
    final fileState = file.currentResult as ParsedMoorFile;

    final writer = Writer(
        const MoorOptions.defaults(generateNamedParameters: true),
        generationOptions: const GenerationOptions(nnbd: true));
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
    }, enableAnalyzer: false);
    addTearDown(state.close);

    final file = await state.analyze('package:a/main.moor');
    final fileState = file.currentResult as ParsedMoorFile;

    final writer = Writer(
        const MoorOptions.defaults(newSqlCodeGeneration: true),
        generationOptions: const GenerationOptions(nnbd: true));
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
    }, enableAnalyzer: false);
    addTearDown(state.close);

    final file = await state.analyze('package:a/main.moor');
    final fileState = file.currentResult as ParsedMoorFile;

    final writer = Writer(
        const MoorOptions.defaults(newSqlCodeGeneration: true),
        generationOptions: const GenerationOptions(nnbd: true));
    QueryWriter(writer.child()).write(fileState.resolvedQueries!.single);

    expect(
      writer.writeGenerated(),
      allOf(
        contains('SELECT"t"."id" AS "nested_0.id"'),
        contains('final TblData tableName;'),
      ),
    );
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

    Future<void> _runTest(MoorOptions options, Matcher expectation) async {
      final file = await state.analyze('package:a/main.moor');
      final fileState = file.currentResult as ParsedMoorFile;

      expect(file.errors.errors, isEmpty);

      final writer = Writer(
        options,
        generationOptions: const GenerationOptions(nnbd: true),
      );
      QueryWriter(writer.child()).write(fileState.resolvedQueries!.single);

      expect(writer.writeGenerated(), expectation);
    }

    test('with the old query generator', () {
      return _runTest(
        const MoorOptions.defaults(),
        allOf(
          contains(r'var $arrayStartIndex = 2;'),
          contains(r'SELECT * FROM tbl WHERE a = :a AND b IN ($expandedb) '
              'AND c = :c'),
          contains(r'variables: [Variable<String?>(a), for (var $ in b) '
              r'Variable<String?>($), Variable<String?>(c)]'),
        ),
      );
    });

    test('with the new query generator', () {
      return _runTest(
        const MoorOptions.defaults(newSqlCodeGeneration: true),
        allOf(
          contains(r'var $arrayStartIndex = 3;'),
          contains(r'SELECT * FROM tbl WHERE a = ?1 AND b IN ($expandedb) '
              'AND c = ?2'),
          contains(r'variables: [Variable<String?>(a), Variable<String?>(c), '
              r'for (var $ in b) Variable<String?>($)], readsFrom: {tbl'),
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

          query: SELECT a, LIST(SELECT b, c FROM tbl WHERE a = :a AND b = :b) FROM tbl WHERE a = :a;
        ''',
      });
    });

    tearDown(() => state.close());

    Future<void> _runTest(
        MoorOptions options, List<Matcher> expectation) async {
      final file = await state.analyze('package:a/main.moor');
      final fileState = file.currentResult as ParsedMoorFile;

      expect(file.errors.errors, isEmpty);

      final writer = Writer(
        options,
        generationOptions: const GenerationOptions(nnbd: true),
      );
      QueryWriter(writer.child()).write(fileState.resolvedQueries!.single);

      final result = writer.writeGenerated();
      for (final e in expectation) {
        expect(result, e);
      }
    }

    test('should error with old generator', () async {
      final file = await state.analyze('package:a/main.moor');
      final fileState = file.currentResult as ParsedMoorFile;

      expect(file.errors.errors, isEmpty);

      final writer = Writer(
        const MoorOptions.defaults(newSqlCodeGeneration: false),
        generationOptions: const GenerationOptions(nnbd: true),
      );

      expect(
        () => QueryWriter(writer.child())
            .write(fileState.resolvedQueries!.single),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('with the new query generator', () {
      return _runTest(
        const MoorOptions.defaults(newSqlCodeGeneration: true),
        [
          contains('SELECT a FROM tbl WHERE a = ?1'),
          contains('SELECT b, c FROM tbl WHERE a = ?1 AND b = ?2'),
          contains('nestedQuery0: await'),
          contains('variables: [Variable<String?>(a), Variable<String?>(b)]'),
          contains('b: row.read<String?>(\'b\')'),
          contains('c: row.read<String?>(\'c\')'),
          contains('class QueryNestedQuery0'),
        ],
      );
    });
  });
}
