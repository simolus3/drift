import 'package:source_span/source_span.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('BEGIN', () {
    test('without mode', () {
      testStatement('BEGIN;', BeginTransactionStatement());
      testStatement('BEGIN TRANSACTION;', BeginTransactionStatement());
    });

    test('deferred', () {
      testStatement(
        'BEGIN DEFERRED;',
        BeginTransactionStatement(TransactionMode.deferred),
      );
    });

    test('immediate', () {
      testStatement(
        'BEGIN IMMEDIATE;',
        BeginTransactionStatement(TransactionMode.immediate),
      );
    });

    test('exclusive', () {
      testStatement(
        'BEGIN EXCLUSIVE TRANSACTION;',
        BeginTransactionStatement(TransactionMode.exclusive),
      );
    });
  });

  test('COMMIT', () {
    testStatement('COMMIT', CommitStatement());
    testStatement('END', CommitStatement());
    testStatement('COMMIT TRANSACTION', CommitStatement());
    testStatement('END TRANSACTION', CommitStatement());
  });

  test('savepoint', () {
    testStatement('SAVEPOINT foo', SavepointStatement('foo'));
  });

  test('release', () {
    testStatement('RELEASE foo', ReleaseStatement('foo'));
    testStatement('RELEASE SAVEPOINT foo', ReleaseStatement('foo'));
  });

  test('rollback', () {
    testStatement('ROLLBACK', RollbackStatement());
    testStatement('ROLLBACK TRANSACTION', RollbackStatement());

    testStatement('ROLLBACK TO foo', RollbackStatement(toSavepoint: 'foo'));
    testStatement(
      'ROLLBACK TO SAVEPOINT foo',
      RollbackStatement(toSavepoint: 'foo'),
    );
    testStatement(
      'ROLLBACK TRANSACTION TO SAVEPOINT foo',
      RollbackStatement(toSavepoint: 'foo'),
    );
  });

  test('reindex', () {
    testStatement('REINDEX foo', ReindexStatement(elementName: 'foo'));
    testStatement(
      'REINDEX foo.bar',
      ReindexStatement(schemaName: 'foo', elementName: 'bar'),
    );
  });

  test('vacuum', () {
    testStatement('VACUUM', VacuumStatement());
    testStatement('VACUUM schema', VacuumStatement(schemaName: 'schema'));
    testStatement(
      'VACUUM INTO ?',
      VacuumStatement(into: NumberedVariable(null)),
    );
    testStatement(
      'VACUUM schema INTO ?',
      VacuumStatement(schemaName: 'schema', into: NumberedVariable(null)),
    );
  });

  test('attach', () {
    testStatement(
      'ATTACH ? AS foo',
      AttachStatement(path: NumberedVariable(null), as: AliasClause('foo')),
    );
    testStatement(
      'ATTACH DATABASE ? AS bar',
      AttachStatement(path: NumberedVariable(null), as: AliasClause('bar')),
    );
  });

  test('detach', () {
    testStatement('DETACH foo', DetachStatement('foo'));
    testStatement('DETACH DATABASE bar', DetachStatement('bar'));
  });

  test('analyze', () {
    testStatement('ANALYZE', AnalyzeStatement());
    testStatement('ANALYZE a', AnalyzeStatement(elementName: 'a'));
    testStatement(
      'ANALYZE a.b',
      AnalyzeStatement(schemaName: 'a', elementName: 'b'),
    );
  });

  test('pragma', () {
    testStatement('PRAGMA foo', PragmaCommand(pragmaName: 'foo'));
    testStatement(
      'PRAGMA foo.bar',
      PragmaCommand(schemaName: 'foo', pragmaName: 'bar'),
    );

    testStatement(
      'PRAGMA foo = 1',
      PragmaCommand(pragmaName: 'foo', value: NumericLiteral(1)),
    );
    testStatement(
      'PRAGMA foo = true',
      PragmaCommand(pragmaName: 'foo', value: BooleanLiteral(true)),
    );
    testStatement(
      'PRAGMA foo = on',
      PragmaCommand(
        pragmaName: 'foo',
        value: Reference(columnName: 'on'),
      ),
    );
    testStatement(
      'PRAGMA foo(on)',
      PragmaCommand(
        pragmaName: 'foo',
        value: Reference(columnName: 'on'),
      ),
    );
  });

  test('can parse substring', () {
    final engine = SqlEngine();
    final source = SourceFile.fromString('PREFIXSELECT * FROM fooSUFFIX');
    final parsed = engine.parseSpan(
      ParserEntrypoint.statement,
      source.span(6, 23),
    );
    expect(parsed.errors, isEmpty);
    expect(parsed.sql.text, 'SELECT * FROM foo');
    expect(parsed.rootNode.span!.text, 'SELECT * FROM foo');
  });

  test('empty source', () {
    final engine = SqlEngine();

    for (final source in ['', '-- comment only']) {
      final stmt = parseStatement(source);
      expect(stmt, isA<InvalidStatement>());

      final multiple = engine.parse(.multiple, source);
      expect(multiple.errors, isEmpty);
      expect(multiple.rootNode.statements, isEmpty);
    }
  });
}
