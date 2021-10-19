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
    QueryWriter(fileState.resolvedQueries!.single, writer.child()).write();

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
    QueryWriter(fileState.resolvedQueries!.single, writer.child()).write();

    expect(
      writer.writeGenerated(),
      allOf(
        contains('SELECT * FROM tbl LIMIT ?2 OFFSET ?1'),
        contains('variables: [Variable<int>(offset), Variable<int>(limit)]'),
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
      QueryWriter(fileState.resolvedQueries!.single, writer.child()).write();

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
}
