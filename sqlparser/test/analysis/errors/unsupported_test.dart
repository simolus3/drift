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
}
