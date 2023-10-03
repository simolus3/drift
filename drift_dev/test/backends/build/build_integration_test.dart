import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:drift_dev/src/backends/build/analyzer.dart';
import 'package:drift_dev/src/backends/build/drift_builder.dart';
import 'package:drift_dev/src/backends/build/exception.dart';
import 'package:drift_dev/src/backends/build/preprocess_builder.dart';
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

CREATE INDEX b_idx /* comment should be stripped */ ON b (foo, upper(foo));
''',
      'a|lib/b.drift': 'CREATE TABLE b (foo TEXT);',
    });

    checkOutputs({
      'a|lib/main.drift.dart': decodedMatches(contains(
          'late final Index bIdx =\n'
          "      Index('b_idx', 'CREATE INDEX b_idx ON b (foo, upper(foo))')")),
    }, result.dartOutputs, result.writer);
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

@DriftDatabase(tables: [FooTable], include: {'queries.drift'})
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
    }, result.dartOutputs, result.writer);
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
      result.writer,
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

    checkOutputs({}, result.dartOutputs, result.writer);
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
    }, result.dartOutputs, result.writer);
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
    }, result.dartOutputs, result.writer);
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
    }, results.dartOutputs, results.writer);
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
                ''''CREATE VIEW my_view AS SELECT CAST(1 AS INT) AS c1, CAST(\\'bar\\' AS TEXT) AS c2, 1 AS c3, NULLIF(1, 2) AS c4','''),
            contains(r'$converterc1 ='),
            contains(r'$converterc2 ='),
            contains(r'$converterc3 ='),
            contains(r'$converterc4 ='),
            contains(r'$converterc4n ='),
          ),
        ),
      },
      result.dartOutputs,
      result.writer,
    );
  });

  test('can restore types from multiple hints', () async {
    final result = await emulateDriftBuild(
      inputs: {
        'a|lib/a.drift': '''
import 'table.dart';

CREATE VIEW my_view AS SELECT foo FROM my_table;
''',
        'a|lib/table.dart': '''
import 'package:drift/drift.dart';

class MyTable extends Table {
  Int64Column get foo => int64().map(myConverter())();
}

enum MyEnum {
  foo, bar
}

TypeConverter<Object, BigInt> myConverter() => throw UnimplementedError();
''',
      },
      modularBuild: true,
      logger: loggerThat(neverEmits(anything)),
    );

    checkOutputs(
      {
        'a|lib/a.drift.dart': decodedMatches(contains(
            'foo: i2.\$MyTableTable.\$converterfoo.fromSql(attachedDatabase.typeMapping\n'
            '          .read(i0.DriftSqlType.bigInt')),
        'a|lib/table.drift.dart': decodedMatches(anything),
      },
      result.dartOutputs,
      result.writer,
    );
  });

  test('supports @create queries in modular generation', () async {
    final result = await emulateDriftBuild(
      inputs: {
        'a|lib/a.drift': '''
CREATE TABLE foo (bar INTEGER PRIMARY KEY);

@create: INSERT INTO foo VALUES (1);
''',
        'a|lib/db.dart': r'''
import 'package:drift/drift.dart';

import 'db.drift.dart';

@DriftDatabase(include: {'a.drift'})
class Database extends $Database {}
''',
      },
      modularBuild: true,
      logger: loggerThat(neverEmits(anything)),
    );

    checkOutputs({
      'a|lib/a.drift.dart':
          decodedMatches(contains(r'OnCreateQuery get $drift0 => ')),
      'a|lib/db.drift.dart': decodedMatches(contains(r'.$drift0];'))
    }, result.dartOutputs, result.writer);
  });

  test('writes query from transitive import', () async {
    final result = await emulateDriftBuild(
      inputs: {
        'a|lib/main.dart': '''
import 'package:drift/drift.dart';

@DriftDatabase(include: {'a.drift'})
class MyDatabase {}
''',
        'a|lib/a.drift': '''
import 'b.drift';

CREATE TABLE foo (bar INTEGER);
''',
        'a|lib/b.drift': '''
import 'c.drift';

CREATE TABLE foo2 (bar INTEGER);
''',
        'a|lib/c.drift': '''
q: SELECT 1;
''',
      },
      logger: loggerThat(neverEmits(anything)),
    );

    checkOutputs({
      'a|lib/main.drift.dart': decodedMatches(
        contains(r'Selectable<int> q()'),
      )
    }, result.dartOutputs, result.writer);
  });

  test('warns when Dart tables are included', () async {
    await emulateDriftBuild(
      inputs: {
        'a|lib/main.dart': '''
import 'package:drift/drift.dart';

@DriftDatabase(include: {'b.dart'})
class MyDatabase {}
''',
        'a|lib/b.dart': '''
import 'package:drift/drift.dart';

class MyTable extends Table {
  IntColumn get id => integer().primaryKey()();
}
''',
      },
      logger: loggerThat(emits(emits(isA<LogRecord>().having((e) => e.message,
          'message', contains('will be included in this database: MyTable'))))),
    );
  });

  test('writes preamble', () async {
    final outputs = await emulateDriftBuild(
      inputs: {
        'a|lib/main.dart': '''
import 'package:drift/drift.dart';

part 'main.drift.dart';

@DriftDatabase()
class MyDatabase {}
''',
      },
      options: BuilderOptions({
        'preamble': '// generated by drift',
      }),
    );

    checkOutputs({
      'a|lib/main.drift.dart': decodedMatches(
        startsWith('// generated by drift\n'),
      ),
    }, outputs.dartOutputs, outputs.writer);
  });

  test('crawl imports through export', () async {
    final outputs = await emulateDriftBuild(
      inputs: {
        'a|lib/table.dart': '''
import 'package:drift/drift.dart';

class MyTable extends Table {
  IntColumn get id => integer().autoIncrement()();
}
''',
        'a|lib/barrel.dart': '''
export 'table.dart';
''',
        'a|lib/database.dart': r'''
import 'package:drift/drift.dart';

import 'barrel.dart';

@DriftDatabase(tables: [MyTable])
class AppDatabase extends $AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
''',
      },
      modularBuild: true,
      logger: loggerThat(neverEmits(anything)),
    );

    checkOutputs({
      'a|lib/table.drift.dart': anything,
      'a|lib/database.drift.dart': decodedMatches(contains('myTable')),
    }, outputs.dartOutputs, outputs.writer);
  });

  test('does not read unecessary files', () async {
    final inputs = <String, String>{
      'a|lib/groups.drift': '''
CREATE TABLE "groups" (
  id INTEGER NOT NULL PRIMARY KEY,
  name TEXT NOT NULL
);
''',
      'a|lib/members.drift': '''
import 'groups.drift';
import 'database.dart';

CREATE TABLE memberships (
  "group" INTEGER NOT NULL REFERENCES "groups"(id),
  "user" INTEGER NOT NULL REFERENCES "users" (id),
  PRIMARY KEY ("group", user)
);
''',
      'a|lib/database.dart': '''
import 'package:drift/drift.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
}

@DriftDatabase(include: {'groups.drift', 'members.drift'})
class MyDatabase {

}
''',
    };
    final outputs = await emulateDriftBuild(inputs: inputs);
    final readAssets = outputs.readAssetsByBuilder;

    Matcher onlyReadsJsonsAnd(dynamic other) {
      return everyElement(
        anyOf(
          isA<AssetId>().having((e) => e.extension, 'extension', '.json'),
          other,
        ),
      );
    }

    void expectReadsForBuilder(String input, Type builder, dynamic expected) {
      final actuallyRead = readAssets.remove((builder, input));
      expect(actuallyRead, expected);
    }

    // 1. Preprocess builders read only the drift file itself and no other
    // files.
    for (final input in inputs.keys) {
      if (input.endsWith('.drift')) {
        expectReadsForBuilder(input, PreprocessBuilder, [makeAssetId(input)]);
      }
    }

    // The discover builder needs to analyze Dart files, which in the current
    // resolver implementation means reading all transitive imports as well.
    // However, the discover builder should not read other drift files.
    for (final input in inputs.keys) {
      if (input.endsWith('.drift')) {
        expectReadsForBuilder(input, DriftDiscover, [makeAssetId(input)]);
      } else {
        expectReadsForBuilder(
          input,
          DriftDiscover,
          isNot(
            contains(
              isA<AssetId>().having((e) => e.extension, 'extension', '.drift'),
            ),
          ),
        );
      }
    }

    // Groups has no imports, so the analyzer shouldn't read any source files
    // apart from groups.
    expectReadsForBuilder('a|lib/groups.drift', DriftAnalyzer,
        onlyReadsJsonsAnd(makeAssetId('a|lib/groups.drift')));

    // Members is analyzed next. We don't have analysis results for the dart
    // file yet, so unfortunately that will have to be analyzed twice. But we
    // shouldn't read groups again.
    expectReadsForBuilder('a|lib/members.drift', DriftAnalyzer,
        isNot(contains(makeAssetId('a|lib/groups.drift'))));

    // Similarly, analyzing the Dart file should not read the includes since
    // those have already been analyzed.
    expectReadsForBuilder(
      'a|lib/database.dart',
      DriftAnalyzer,
      isNot(
        contains(
          isA<AssetId>().having((e) => e.extension, 'extension', '.drift'),
        ),
      ),
    );

    // The final builder needs to run file analysis which requires resolving
    // the input file fully. Unfortunately, resolving queries also needs access
    // to the original source so there's not really anything we could test.
    expectReadsForBuilder('a|lib/database.dart', DriftBuilder, anything);

    // Make sure we didn't forget an assertion.
    expect(readAssets, isEmpty);
  });

  group('reports issues', () {
    for (final fatalWarnings in [false, true]) {
      group('fatalWarnings: $fatalWarnings', () {
        final options = BuilderOptions(
          {'fatal_warnings': fatalWarnings},
          isRoot: true,
        );

        Future<void> runTest(String source, expectedMessage) async {
          final build = emulateDriftBuild(
            inputs: {'a|lib/a.drift': source},
            logger: loggerThat(emits(isA<LogRecord>()
                .having((e) => e.message, 'message', expectedMessage))),
            modularBuild: true,
            options: options,
          );

          if (fatalWarnings) {
            await expectLater(build, throwsA(isA<FatalWarningException>()));
          } else {
            await build;
          }
        }

        test('syntax', () async {
          await runTest(
              'foo: SELECT;', contains('Could not parse this expression'));
        });

        test('semantic in analysis', () async {
          await runTest('''
            CREATE TABLE foo (
              id INTEGER NOT NULL PRIMARY KEY,
              unknown INTEGER NOT NULL REFERENCES another ("table")
            );
          ''', contains('could not be found in any import.'));
        });

        test('file analysis', () async {
          await runTest(
              r'a($x = 2): SELECT 1, 2, 3 ORDER BY $x;',
              contains('This placeholder has a default value, which is only '
                  'supported for expressions.'));
        });
      });
    }
  });
}
