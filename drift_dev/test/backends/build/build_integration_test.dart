import 'package:build/build.dart';
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

  test('can work with existing part files', () async {
    final logger = Logger.detached('build');
    expect(logger.onRecord, neverEmits(anything));

    final result = await emulateDriftBuild(
      inputs: {
        'a|lib/main.dart': '''
import 'package:drift/drift.dart';

part 'table.dart';

@DriftDatabase(tables: [Users])
class MyDatabase {}
''',
        'a|lib/table.dart': '''
part of 'main.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}
''',
      },
      logger: logger,
    );

    checkOutputs(
      {'a|lib/main.drift.dart': decodedMatches(contains('class User'))},
      result.dartOutputs,
      result,
    );
  });

  test('handles syntax error in source file', () async {
    final logger = Logger.detached('build');
    expect(
      logger.onRecord,
      emits(
        isA<LogRecord>()
            .having((e) => e.message, 'message',
                contains('Could not resolve Dart library package:a/main.dart'))
            .having(
                (e) => e.error, 'error', isA<SyntaxErrorInAssetException>()),
      ),
    );

    final result = await emulateDriftBuild(
      inputs: {
        'a|lib/main.dart': '''
import 'package:drift/drift.dart';

class Users extends Table {
  IntColumn id => integer().autoIncrement()();
  TextColumn name => text()();
}

@DriftDatabase(tables: [Users])
class MyDatabase {}
''',
      },
      logger: logger,
    );

    checkOutputs({}, result.dartOutputs, result);
  });

  test('generates custom result classes with modular generation', () async {
    final logger = Logger.detached('driftBuild');
    expect(logger.onRecord, neverEmits(anything));

    final result = await emulateDriftBuild(
      inputs: {
        'a|lib/main.drift': '''
firstQuery AS MyResultClass: SELECT 'foo' AS r1, 1 AS r2;
secondQuery AS MyResultClass: SELECT 'bar' AS r1, 2 AS r2;
''',
      },
      modularBuild: true,
      logger: logger,
    );

    checkOutputs({
      'a|lib/main.drift.dart': decodedMatches(predicate((String generated) {
        return 'class MyResultClass'.allMatches(generated).length == 1;
      })),
    }, result.dartOutputs, result);
  });

  test('generates imports for query variables with modular generation',
      () async {
    final result = await emulateDriftBuild(
      inputs: {
        'a|lib/main.drift': '''
CREATE TABLE my_table (
  a INTEGER PRIMARY KEY,
  b TEXT,
  c BLOB,
  d ANY
) STRICT;

q: INSERT INTO my_table (b, c, d) VALUES (?, ?, ?);
''',
      },
      modularBuild: true,
      logger: loggerThat(neverEmits(anything)),
    );

    checkOutputs({
      'a|lib/main.drift.dart': decodedMatches(
        allOf(
          contains(
            'import \'package:drift/drift.dart\' as i0;\n'
            'import \'package:a/main.drift.dart\' as i1;\n'
            'import \'dart:typed_data\' as i2;\n'
            'import \'package:drift/internal/modular.dart\' as i3;\n',
          ),
          contains(
            'class MyTableData extends i0.DataClass\n'
            '    implements i0.Insertable<i1.MyTableData> {\n'
            '  final int a;\n'
            '  final String? b;\n'
            '  final i2.Uint8List? c;\n'
            '  final i0.DriftAny? d;\n',
          ),
          contains(
            '      variables: [\n'
            '        i0.Variable<String>(var1),\n'
            '        i0.Variable<i2.Uint8List>(var2),\n'
            '        i0.Variable<i0.DriftAny>(var3)\n'
            '      ],\n',
          ),
        ),
      ),
    }, result.dartOutputs, result);
  });

  test('supports `MAPPED BY` for columns', () async {
    final results = await emulateDriftBuild(
      inputs: {
        'a|lib/a.drift': '''
import 'converter.dart';

a: SELECT NULLIF(1, 2) MAPPED BY `myConverter()` AS col;
''',
        'a|lib/converter.dart': '''
import 'package:drift/drift.dart';

TypeConverter<Object, int> myConverter() => throw 'stub';
''',
      },
      modularBuild: true,
    );

    checkOutputs({
      'a|lib/a.drift.dart': decodedMatches(contains('''
class ADrift extends i1.ModularAccessor {
  ADrift(i0.GeneratedDatabase db) : super(db);
  i0.Selectable<Object?> a() {
    return customSelect('SELECT NULLIF(1, 2) AS col',
            variables: [], readsFrom: {})
        .map((i0.QueryRow row) => i0.NullAwareTypeConverter.wrapFromSql(
            i2.myConverter(), row.readNullable<int>('col')));
  }
}
''')),
    }, results.dartOutputs, results);
  });

  test('generates type converters for views', () async {
    final result = await emulateDriftBuild(
      inputs: {
        'a|lib/a.drift': '''
import 'converter.dart';

CREATE VIEW my_view AS SELECT
  CAST(1 AS ENUM(MyEnum)) AS c1,
  CAST('bar' AS ENUMNAME(MyEnum)) AS c2,
  1 MAPPED BY `myConverter()` AS c3,
  NULLIF(1, 2) MAPPED BY `myConverter()` AS c4
;
''',
        'a|lib/converter.dart': '''
import 'package:drift/drift.dart';

enum MyEnum {
  foo, bar
}

TypeConverter<Object, int> myConverter() => throw UnimplementedError();
''',
      },
      modularBuild: true,
      logger: loggerThat(neverEmits(anything)),
    );

    checkOutputs(
      {
        'a|lib/a.drift.dart': decodedMatches(
          allOf(
            contains(
                ''''CREATE VIEW my_view AS SELECT CAST(1 AS INT) AS c1, CAST(\\'bar\\' AS TEXT) AS c2, 1 AS c3, NULLIF(1, 2) AS c4';'''),
            contains(r'$converterc1 ='),
            contains(r'$converterc2 ='),
            contains(r'$converterc3 ='),
            contains(r'$converterc4 ='),
            contains(r'$converterc4n ='),
          ),
        ),
      },
      result.dartOutputs,
      result,
    );
  });
}
