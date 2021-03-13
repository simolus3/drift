import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../data.dart';

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
}
