import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  final oldEngine = SqlEngine(EngineOptions(version: SqliteVersion.v3_35));
  final engine = SqlEngine(EngineOptions(version: SqliteVersion.v3_37));

  group('using STRICT', () {
    test('with an old sqlite3 version', () {
      const stmt = 'CREATE TABLE a (c INTEGER) STRICT';

      oldEngine.analyze(stmt).expectError('STRICT',
          type: AnalysisErrorType.notSupportedInDesiredVersion);
      engine.analyze(stmt).expectNoError();
    });

    test(
      'without a column type',
      () {
        engine
            .analyze('CREATE TABLE a (c) STRICT;')
            .expectError('c', type: AnalysisErrorType.noTypeNameInStrictTable);
      },
    );

    test(
      'with an invalid column type',
      () {
        engine.analyze('CREATE TABLE a (c INTEGER(12)) STRICT;').expectError(
              'INTEGER(12)',
              type: AnalysisErrorType.invalidTypeNameInStrictTable,
            );
      },
    );
  });

  test('using WITHOUT ROWID and then not declaring a primary key', () {
    engine
        .analyze('CREATE TABLE a (c INTEGER) WITHOUT ROWID')
        .expectError('a', type: AnalysisErrorType.missingPrimaryKey);

    engine.analyze('CREATE TABLE a (c INTEGER);').expectNoError();
    engine
        .analyze('CREATE TABLE a (c INTEGER PRIMARY KEY) WITHOUT ROWID;')
        .expectNoError();

    final errors =
        engine.analyze('CREATE TABLE a (c INTEGER, PRIMARY KEY (c));');
    expect(
        errors,
        isNot(contains(
            analysisErrorWith(type: AnalysisErrorType.missingPrimaryKey))));
  });

  test('multiple primary key constraints', () {
    engine
        .analyze(
            'CREATE TABLE a (c INTEGER PRIMARY KEY, c2 INTEGER PRIMARY KEY)')
        .expectError('PRIMARY KEY',
            type: AnalysisErrorType.duplicatePrimaryKeyDeclaration);

    final errors = engine
        .analyze('CREATE TABLE a (c INTEGER PRIMARY KEY, c2, PRIMARY KEY (c2))')
        .errors;

    expect(
      errors,
      contains(analysisErrorWith(
          lexeme: 'PRIMARY KEY (c2)',
          type: AnalysisErrorType.duplicatePrimaryKeyDeclaration)),
    );
  });
}
