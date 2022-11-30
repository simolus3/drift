import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import '../../utils.dart';

void main() {
  test('writes entities from imports', () async {
    // Regression test for https://github.com/simolus3/drift/issues/2175
    final result = await emulateDriftBuild(inputs: {
      'a|lib/main.dart': '''
import 'package:drift/drift.dart';

@DriftDatabase(include: {'a.drift'})
class MyDatabase {}
''',
      'a|lib/a.drift': '''
import 'b.drift';

CREATE INDEX b_idx /* comment should be stripped */ ON b (foo);
''',
      'a|lib/b.drift': 'CREATE TABLE b (foo TEXT);',
    });

    checkOutputs({
      'a|lib/main.drift.dart': decodedMatches(contains(
          "late final Index bIdx = Index('b_idx', 'CREATE INDEX b_idx ON b (foo)')")),
    }, result.dartOutputs, result);
  });

  test('warns about errors in imports', () async {
    final logger = Logger.detached('build');
    final logs = logger.onRecord.map((e) => e.message).toList();

    await emulateDriftBuild(
      inputs: {
        'a|lib/main.dart': '''
import 'package:drift/drift.dart';

@DriftDatabase(include: {'a.drift'})
class MyDatabase {}
''',
        'a|lib/a.drift': '''
import 'b.drift';

file_analysis_error(? AS TEXT): SELECT ? IN ?2;
''',
        'a|lib/b.drift': '''
CREATE TABLE syntax_error;

CREATE TABLE a (b TEXT);

CREATE INDEX semantic_error ON a (c);
''',
      },
      logger: logger,
    );

    expect(
      await logs,
      [
        allOf(contains('Expected opening parenthesis'),
            contains('syntax_error;')),
        allOf(contains('Unknown column.'), contains('(c);')),
        allOf(contains('Cannot use an array variable with an explicit index'),
            contains('?2;')),
      ],
    );
  });

  test('Dart-defined tables are visible in drift files', () async {
    final logger = Logger.detached('build');
    expect(logger.onRecord, neverEmits(anything));

    final result = await emulateDriftBuild(
      inputs: {
        'a|lib/database.dart': '''
import 'package:drift/drift.dart';

@DataClassName('DFoo')
class FooTable extends Table {
  @override
  String get tableName => 'foo';

  IntColumn get fooId => integer()();
}

@DriftDatabase(include: {'queries.drift'})
class MyDatabase {}
''',
        'a|lib/tables.drift': '''
import 'database.dart';
''',
        'a|lib/queries.drift': '''
import 'tables.drift';

selectAll: SELECT * FROM foo;
''',
      },
      logger: logger,
    );

    checkOutputs({
      'a|lib/database.drift.dart': decodedMatches(contains('selectAll')),
    }, result.dartOutputs, result);
  });
}
