// tests for syntax errors revealed during static analysis.

import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../data.dart';
import 'utils.dart';

void main() {
  group('DO UPDATE clause without conflict target', () {
    test('is forbidden on older sqlite versions', () {
      final engine = SqlEngine()..registerTable(demoTable);
      final result = engine.analyze('INSERT INTO demo VALUES (?, ?)  '
          'ON CONFLICT DO UPDATE SET id = 3;');

      expect(result.errors, [
        const TypeMatcher<AnalysisError>()
            .having((e) => e.type, 'type', AnalysisErrorType.synctactic)
            .having((e) => e.message, 'message',
                contains('Expected a conflict clause'))
      ]);
    });

    test('is allowed on the last clause', () {
      final engine = SqlEngine(EngineOptions(version: SqliteVersion.v3_35))
        ..registerTable(demoTable);
      expect(
        engine
            .analyze('INSERT INTO demo VALUES (?, ?)  '
                'ON CONFLICT DO UPDATE SET id = 3;')
            .errors,
        isEmpty,
      );
    });

    test('is not allowed on previous clauses', () {
      final engine = SqlEngine(EngineOptions(version: SqliteVersion.v3_35))
        ..registerTable(demoTable);
      expect(
        engine
            .analyze('INSERT INTO demo VALUES (?, ?)  '
                'ON CONFLICT DO UPDATE SET id = 3'
                'ON CONFLICT DO NOTHING;')
            .errors,
        hasLength(1),
      );
    });
  });

  test('complex expressions in PRIMARY KEY clause', () {
    final engine = SqlEngine();
    final parseResult = engine.parse('''
      CREATE TABLE tbl (
        foo INTEGER NOT NULL,
        bar TEXT NOT NULL,
        PRIMARY KEY (foo DESC, bar || 'test')
      );
    ''');
    engine.registerTable(const SchemaFromCreateTable()
        .read(parseResult.rootNode as CreateTableStatement));
    final analyzeResult = engine.analyzeParsed(parseResult);

    expect(analyzeResult.errors, [
      const TypeMatcher<AnalysisError>()
          .having((e) => e.type, 'type', AnalysisErrorType.synctactic)
          .having((e) => e.message, 'message',
              contains('Only column names can be used in a PRIMARY KEY clause'))
    ]);
  });

  group('illegal constructs in triggers', () {
    final engine = SqlEngine()..registerTable(demoTable);

    test('DEFAULT VALUES', () {
      engine.analyze('INSERT INTO demo DEFAULT VALUES').expectNoError();
      engine
          .analyze('CREATE TRIGGER tgr AFTER DELETE ON demo BEGIN '
              'INSERT INTO demo DEFAULT VALUES;'
              'END;')
          .expectError('DEFAULT VALUES', type: AnalysisErrorType.synctactic);
    });

    test('WITH clauses', () {
      // https://sqlite.org/lang_with.html#limitations_and_caveats
      engine.analyze('WITH x AS (SELECT 1) SELECT 2').expectNoError();

      engine.analyze('''
CREATE TRIGGER tgr AFTER INSERT ON demo BEGIN
  WITH x AS (SELECT 1) SELECT 2;
END;
''').expectError('WITH', type: AnalysisErrorType.synctactic);
    });

    group('aliased source tables', () {
      test('insert', () {
        engine.analyze('INSERT INTO demo AS d VALUES (?, ?)').expectNoError();
        engine
            .analyze('CREATE TRIGGER tgr AFTER DELETE ON demo BEGIN '
                'INSERT INTO demo AS d VALUES (?, ?);'
                'END;')
            .expectError('demo AS d', type: AnalysisErrorType.synctactic);
      });

      test('update', () {
        engine.analyze('UPDATE demo AS d SET id = id + 1;').expectNoError();
        engine
            .analyze('CREATE TRIGGER tgr AFTER DELETE ON demo BEGIN '
                'UPDATE demo AS d SET id = id + 1;'
                'END;')
            .expectError('demo AS d', type: AnalysisErrorType.synctactic);
      });

      test('delete', () {
        engine.analyze('DELETE FROM demo d;').expectNoError();
        engine
            .analyze('CREATE TRIGGER tgr AFTER DELETE ON demo BEGIN '
                'DELETE FROM demo d;'
                'END;')
            .expectError('demo d', type: AnalysisErrorType.synctactic);
      });

      test('allowed in subquery', () {
        engine.analyze('''
          CREATE TRIGGER tgr AFTER DELETE ON demo BEGIN
            INSERT INTO demo (content) SELECT content FROM demo AS ok;
          END;
        ''').expectNoError();
      });
    });
  });

  test('window function with order by', () {
    final engine = SqlEngine(EngineOptions(version: SqliteVersion.v3_44))
      ..registerTable(demoTable);

    engine
        .analyze('SELECT group_concat(content ORDER BY id DESC) '
            'OVER (ROWS UNBOUNDED PRECEDING) FROM demo;')
        .expectError('ORDER BY id DESC');
  });
}
