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
}
