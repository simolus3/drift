import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../data.dart';

void main() {
  final engine = SqlEngine(EngineOptions(
    enabledExtensions: const [Fts5Extension()],
    version: SqliteVersion.v3_35,
  ))
    ..registerTableFromSql('CREATE TABLE t (id INTEGER PRIMARY KEY, c2 TEXT);')
    ..registerTableFromSql(
        'CREATE VIRTUAL TABLE vt USING fts5 (foo, bar, baz);');

  test('does not allow RETURNING for statements in triggers', () {
    final result = engine.analyze('''
    CREATE TRIGGER my_trigger AFTER INSERT ON t BEGIN
      INSERT INTO t VALUES (1, '') RETURNING *;
    END;
    ''');

    expect(result.errors, hasLength(1));
    expect(result.errors.single.type, AnalysisErrorType.illegalUseOfReturning);
  });

  test('does not allow RETURNING on virtual tables', () {
    final result =
        engine.analyze("INSERT INTO vt VALUES ('', '', '') RETURNING *;");

    expect(result.errors, hasLength(1));
    expect(result.errors.single.type, AnalysisErrorType.illegalUseOfReturning);
  });

  test('does not allow star columns with an associated table', () {
    final result = engine.analyze('''
      UPDATE t SET id = t.id + 1
        FROM (SELECT * FROM t) AS old
        RETURNING old.*;
    ''');

    expect(result.errors, hasLength(1));
    expect(
      result.errors.single,
      isA<AnalysisError>()
          .having((e) => e.source!.span!.text, 'source.span.text', 'old.*')
          .having((e) => e.message, 'message',
              contains('RETURNING may not use the TABLE.* syntax')),
    );
  });

  test('does not allow aggregate expressions', () {
    final result = engine.analyze('INSERT INTO t DEFAULT VALUES RETURNING '
        'MAX(id) OVER (PARTITION BY c2)');

    expect(result.errors, hasLength(1));
    expect(
      result.errors.single,
      isA<AnalysisError>()
          .having((e) => e.source!.span!.text, 'source.span.text',
              'MAX(id) OVER (PARTITION BY c2)')
          .having((e) => e.message, 'message',
              'Aggregate expressions are not allowed in RETURNING'),
    );
  });
}
