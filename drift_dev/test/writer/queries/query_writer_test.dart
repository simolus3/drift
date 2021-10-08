// @dart=2.9
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
    QueryWriter(fileState.resolvedQueries.single, writer.child()).write();

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
    QueryWriter(fileState.resolvedQueries.single, writer.child()).write();

    expect(
      writer.writeGenerated(),
      allOf(
        contains('SELECT * FROM tbl LIMIT ?2 OFFSET ?1'),
        contains('variables: [Variable<int>(offset), Variable<int>(limit)]'),
      ),
    );
  });
}
