import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../data.dart';
import 'utils.dart';

void main() {
  final minimumEngine = SqlEngine()..registerTable(demoTable);
  final currentEngine = SqlEngine(EngineOptions(version: SqliteVersion.current))
    ..registerTable(demoTable);

  test('reports error for MATERIALIZED in CTEs', () {
    const sql = '''
      WITH foo (x) AS MATERIALIZED (SELECT 1) SELECT 2;
    ''';
    final context = minimumEngine.analyze(sql);
    expect(context.errors, hasLength(1));
    expect(
      context.errors.single,
      isA<AnalysisError>()
          .having((e) => e.message, 'message',
              contains('requires sqlite3 version 35'))
          .having((e) => e.span!.text, 'span.text', 'MATERIALIZED'),
    );

    expect(currentEngine.analyze(sql).errors, isEmpty);
  });

  test('reports error for multiple ON CONFLICT clauses', () {
    const sql = '''
      INSERT INTO demo VALUES (3, 'hi')
        ON CONFLICT (content) DO NOTHING
        ON CONFLICT (id) DO UPDATE SET content = 'reset';
    ''';

    final context = minimumEngine.analyze(sql);
    expect(context.errors, hasLength(1));
    expect(
      context.errors.single,
      isA<AnalysisError>().having((e) => e.message, 'message',
          contains('require sqlite version 3.35 or later')),
    );

    expect(currentEngine.analyze(sql).errors, isEmpty);
  });

  test('reports error for RETURNING on unsupported errors', () {
    const sql = '''
      UPDATE demo SET content = content || content RETURNING *;
    ''';

    final context = minimumEngine.analyze(sql);
    expect(context.errors, hasLength(1));
    expect(
      context.errors.single,
      isA<AnalysisError>().having((e) => e.message, 'message',
          'RETURNING requires sqlite version 3.35 or later'),
    );

    expect(currentEngine.analyze(sql).errors, isEmpty);
  });

  test('reports error for STRICT on an old sqlite3 version', () {
    const sql = 'CREATE TABLE a (b TEXT) STRICT';

    final context = minimumEngine.analyze(sql);
    expect(context.errors, hasLength(1));
    context.expectError('STRICT',
        type: AnalysisErrorType.notSupportedInDesiredVersion);

    expect(currentEngine.analyze(sql).errors, isEmpty);
  });

  test('does not support `->` and `->>`in old sqlite3 versions', () {
    minimumEngine.analyze("SELECT '' -> ''").expectError('->',
        type: AnalysisErrorType.notSupportedInDesiredVersion);
    minimumEngine.analyze("SELECT '' ->> ''").expectError('->>',
        type: AnalysisErrorType.notSupportedInDesiredVersion);

    currentEngine.analyze("SELECT '' -> ''").expectNoError();
    currentEngine.analyze("SELECT '' ->> ''").expectNoError();
  });

  test('warns about using `printf` after 3.38', () {
    const sql = "SELECT printf('', 0, 'foo')";

    currentEngine
        .analyze(sql)
        .expectError("printf('', 0, 'foo')", type: AnalysisErrorType.hint);
    minimumEngine.analyze(sql).expectNoError();
  });

  test('warns about using unixepoch before 3.38', () {
    const sql = "SELECT unixepoch('')";

    minimumEngine.analyze(sql).expectError('unixepoch',
        type: AnalysisErrorType.notSupportedInDesiredVersion);
    currentEngine.analyze(sql).expectNoError();
  });

  test('warns about using format before 3.38', () {
    const sql = "SELECT format('', 0, 'foo')";

    minimumEngine.analyze(sql).expectError('format',
        type: AnalysisErrorType.notSupportedInDesiredVersion);
    currentEngine.analyze(sql).expectNoError();
  });

  test('warns about unhex before 3.41', () {
    const sql = "SELECT unhex('abcd')";

    minimumEngine.analyze(sql).expectError('unhex',
        type: AnalysisErrorType.notSupportedInDesiredVersion);
    currentEngine.analyze(sql).expectNoError();
  });

  test('warns about timediff before 3.43', () {
    const sql = "SELECT timediff(?, ?)";

    minimumEngine.analyze(sql).expectError('timediff',
        type: AnalysisErrorType.notSupportedInDesiredVersion);
    currentEngine.analyze(sql).expectNoError();
  });

  test('warns about octet_length before 3.43', () {
    const sql = "SELECT octet_length('abcd')";

    minimumEngine.analyze(sql).expectError('octet_length',
        type: AnalysisErrorType.notSupportedInDesiredVersion);
    currentEngine.analyze(sql).expectNoError();
  });

  test('warns about `IS DISTINCT FROM`', () {
    const sql = 'SELECT id IS DISTINCT FROM content FROM demo;';
    const notSql = 'SELECT id IS NOT DISTINCT FROM content FROM demo;';

    minimumEngine.analyze(sql).expectError('DISTINCT FROM',
        type: AnalysisErrorType.notSupportedInDesiredVersion);
    minimumEngine.analyze(notSql).expectError('DISTINCT FROM',
        type: AnalysisErrorType.notSupportedInDesiredVersion);

    currentEngine.analyze(sql).expectNoError();
    currentEngine.analyze(notSql).expectNoError();
  });

  test('warns about right and full joins', () {
    const right = 'SELECT * FROM demo RIGHT JOIN demo';
    const full = 'SELECT * FROM demo NATURAL FULL JOIN demo';

    minimumEngine.analyze(right).expectError('RIGHT JOIN',
        type: AnalysisErrorType.notSupportedInDesiredVersion);
    minimumEngine.analyze(full).expectError('NATURAL FULL JOIN',
        type: AnalysisErrorType.notSupportedInDesiredVersion);

    currentEngine.analyze(right).expectNoError();
    currentEngine.analyze(full).expectNoError();
  });
}
