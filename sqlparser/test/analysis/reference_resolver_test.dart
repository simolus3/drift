import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/utils/ast_equality.dart';
import 'package:test/test.dart';

import '../parser/utils.dart';
import 'data.dart';
import 'errors/utils.dart';

void main() {
  test('correctly resolves return columns', () {
    final engine = SqlEngine()..registerTable(demoTable);

    final context =
        engine.analyze('SELECT id, d.content, *, 3 + 4 FROM demo AS d '
            'WHERE _rowid_ = 3');

    final select = context.root as SelectStatement;
    final resolvedColumns = select.resolvedColumns!;

    expect(context.errors, isEmpty);

    expect(resolvedColumns.map((c) => c.name),
        ['id', 'content', 'id', 'content', '3 + 4']);

    expect(resolvedColumns.map((c) => context.typeOf(c).type!.type), [
      BasicType.int,
      BasicType.text,
      BasicType.int,
      BasicType.text,
      BasicType.int,
    ]);

    final firstColumn = select.columns[0] as ExpressionResultColumn;
    final secondColumn = select.columns[1] as ExpressionResultColumn;
    final from = select.from as TableReference;

    expect((firstColumn.expression as Reference).resolvedColumn?.source, id);
    expect(
        (secondColumn.expression as Reference).resolvedColumn?.source, content);
    expect(from.resultSet?.unalias(), demoTable);

    final where = select.where as BinaryExpression;
    expect((where.left as Reference).resolved, id);
  });

  test('resolves columns from views', () {
    final engine = SqlEngine()..registerTable(demoTable);

    final viewCtx = engine.analyze('CREATE VIEW my_view (foo, bar) AS '
        'SELECT * FROM demo;');
    engine.registerView(engine.schemaReader
        .readView(viewCtx, viewCtx.root as CreateViewStatement));

    final context = engine.analyze('SELECT * FROM my_view');
    expect(context.errors, isEmpty);

    final resolvedColumns = (context.root as SelectStatement).resolvedColumns!;
    expect(resolvedColumns.map((e) => e.name), ['foo', 'bar']);
    expect(
      resolvedColumns.map((e) => context.typeOf(e).type!.type),
      [BasicType.int, BasicType.text],
    );
  });

  test("resolved columns don't include drift nested results", () {
    final engine =
        SqlEngine(EngineOptions(driftOptions: const DriftSqlOptions()))
          ..registerTable(demoTable);

    final context = engine.analyze('SELECT demo.** FROM demo;');

    expect(context.errors, isEmpty);
    expect((context.root as SelectStatement).resolvedColumns, isEmpty);
  });

  test('resolves the column for order by clauses', () {
    final engine = SqlEngine()..registerTable(demoTable);

    final context = engine
        .analyze('SELECT d.content, 3 * d.id AS t FROM demo AS d ORDER BY t');

    expect(context.errors, isEmpty);

    final select = context.root as SelectStatement;
    final term = (select.orderBy as OrderBy).terms.single as OrderingTerm;
    final expression = term.expression as Reference;
    final resolved = expression.resolved as ExpressionColumn;

    enforceEqual(
      resolved.expression,
      BinaryExpression(
        NumericLiteral(3),
        token(TokenType.star),
        Reference(entityName: 'd', columnName: 'id'),
      ),
    );
  });

  test('allows references to result column in group by', () {
    // https://github.com/simolus3/drift/issues/2378
    final engine = SqlEngine()
      ..registerTableFromSql('CREATE TABLE foo (bar INTEGER);');

    final result = engine.analyze('''
      SELECT *, bar > 20 AS test FROM foo GROUP BY bar HAVING test
''');

    expect(result.errors, isEmpty);
  });

  test('does not allow references to result column outside of ORDER BY', () {
    final engine = SqlEngine()..registerTable(demoTable);

    final context = engine
        .analyze('SELECT d.content, 3 * d.id AS t, t AS u FROM demo AS d');

    context.expectError('t', type: AnalysisErrorType.referencedUnknownColumn);
  });

  test('resolves columns from nested results', () {
    final engine =
        SqlEngine(EngineOptions(driftOptions: const DriftSqlOptions()))
          ..registerTable(demoTable)
          ..registerTable(anotherTable);

    final context = engine.analyze('SELECT SUM(*) AS rst FROM '
        '(SELECT COUNT(*) FROM demo UNION ALL SELECT COUNT(*) FROM tbl);');

    expect(context.errors, isEmpty);

    final select = context.root as SelectStatement;
    expect(select.resolvedColumns, hasLength(1));
    expect(
      context.typeOf(select.resolvedColumns!.single).type!.type,
      BasicType.int,
    );
  });

  test('resolves columns in nested queries', () {
    final engine =
        SqlEngine(EngineOptions(driftOptions: const DriftSqlOptions()))
          ..registerTable(demoTable);

    final context =
        engine.analyze('SELECT content, LIST(SELECT id FROM demo) FROM demo');

    expect(context.errors, isEmpty);

    final select = context.root as SelectStatement;
    final nestedQuery = select.columns[1] as NestedQueryColumn;

    expect(nestedQuery.select.columns, hasLength(1));
    expect(
      context.typeOf(nestedQuery.select.resolvedColumns!.single).type!.type,
      BasicType.int,
    );
  });

  group('reports correct column name for rowid aliases', () {
    final engine = SqlEngine()
      ..registerTable(demoTable)
      ..registerTable(anotherTable);

    test('when virtual id', () {
      final context = engine.analyze('SELECT oid, _rowid_ FROM tbl');
      final select = context.root as SelectStatement;
      final resolvedColumns = select.resolvedColumns!;

      expect(resolvedColumns.map((c) => c.name), ['rowid', 'rowid']);
    });

    test('when alias to actual column', () {
      final context = engine.analyze('SELECT oid, _rowid_ FROM demo');
      final select = context.root as SelectStatement;
      final resolvedColumns = select.resolvedColumns!;

      expect(resolvedColumns.map((c) => c.name), ['id', 'id']);
    });
  });

  group('sub-queries', () {
    test('are resolved', () {
      final engine = SqlEngine()..registerTable(demoTable);

      final context = engine.analyze(
          'SELECT d.*, (SELECT id FROM demo WHERE id = d.id) FROM demo d;');

      expect(context.errors, isEmpty);
    });

    test('cannot refer to outer tables if used in FROM', () {
      final engine = SqlEngine()..registerTable(demoTable);

      final context = engine.analyze(
          'SELECT d.* FROM demo d, (SELECT * FROM demo WHERE id = d.id);');

      context.expectError('d.id',
          type: AnalysisErrorType.referencedUnknownTable);
    });

    test('can refer to CTEs if used in FROM', () {
      final engine = SqlEngine()..registerTable(demoTable);

      final context = engine.analyze('WITH cte AS (SELECT * FROM demo) '
          'SELECT d.* FROM demo d, (SELECT * FROM cte);');

      expect(context.errors, isEmpty);
    });

    test('can nest and see outer tables if that is a subquery', () {
      final engine = SqlEngine()..registerTable(demoTable);

      final context = engine.analyze('''
SELECT
  (SELECT *
   FROM
     demo "inner",
     (SELECT * FROM demo WHERE "inner".id = "outer".id)
  )
  FROM demo "outer";
''');

      // note that "outer".id is visible and should not report an error
      context.expectError('"inner".id',
          type: AnalysisErrorType.referencedUnknownTable);
    });

    test('nested via FROM cannot see outer result sets', () {
      final engine = SqlEngine()..registerTable(demoTable);

      final context = engine.analyze('''
SELECT *
  FROM
    demo "outer",
    (SELECT * FROM demo "inner",
      (SELECT * FROM demo WHERE "inner".id = "outer".id))
''');

      expect(
        context.errors,
        [
          analysisErrorWith(
            lexeme: '"inner".id',
            type: AnalysisErrorType.referencedUnknownTable,
          ),
          analysisErrorWith(
            lexeme: '"outer".id',
            type: AnalysisErrorType.referencedUnknownTable,
          ),
        ],
      );
    });
  });

  test('resolves sub-queries as data sources', () {
    final engine = SqlEngine()
      ..registerTable(demoTable)
      ..registerTable(anotherTable);

    final context = engine.analyze('SELECT d.* FROM demo d INNER JOIN tbl '
        'ON tbl.id = (SELECT id FROM tbl WHERE date = ? AND id = d.id)');

    expect(context.errors, isEmpty);
  });

  test('resolves window declarations', () {
    final engine = SqlEngine()..registerTable(demoTable);

    final context = engine.analyze('''
SELECT row_number() OVER wnd FROM demo
  WINDOW wnd AS (PARTITION BY content GROUPS CURRENT ROW EXCLUDE TIES)
    ''');

    final column = (context.root as SelectStatement).resolvedColumns!.single
        as ExpressionColumn;

    final over = (column.expression as WindowFunctionInvocation).over!;

    enforceEqual(
      over,
      WindowDefinition(
        partitionBy: [Reference(columnName: 'content')],
        frameSpec: FrameSpec(
          type: FrameType.groups,
          start: FrameBoundary.currentRow(),
          excludeMode: ExcludeMode.ties,
        ),
      ),
    );
  });

  test('warns about ambigious references', () {
    final engine = SqlEngine()..registerTable(demoTable);

    final context =
        engine.analyze('SELECT id FROM demo, (SELECT id FROM demo) AS a');
    expect(context.errors, hasLength(1));
    expect(
      context.errors.single,
      isA<AnalysisError>()
          .having((e) => e.type, 'type', AnalysisErrorType.ambiguousReference)
          .having((e) => e.span?.text, 'span.text', 'id'),
    );
  });

  test("does not allow columns from tables that haven't been added", () {
    final engine = SqlEngine()..registerTable(demoTable);

    final context = engine.analyze('SELECT demo.id;');
    expect(context.errors, hasLength(1));
    expect(
        context.errors.single,
        isA<AnalysisError>()
            .having(
                (e) => e.type, 'type', AnalysisErrorType.referencedUnknownTable)
            .having((e) => e.span?.text, 'span.text', 'demo.id'));
  });

  group('nullability for references from outer join', () {
    final engine = SqlEngine()
      ..registerTableFromSql('''
      CREATE TABLE users (
        id INTEGER NOT NULL PRIMARY KEY
      );
    ''')
      ..registerTableFromSql('''
      CREATE TABLE messages (
        sender INTEGER NOT NULL
      );
    ''');

    void testWith(String sql) {
      final context = engine.analyze(sql);

      expect(context.errors, isEmpty);
      final columns = (context.root as SelectStatement).resolvedColumns!;

      expect(columns.map((e) => e.name), ['sender', 'id']);
      expect(context.typeOf(columns[0]).nullable, isFalse);
      expect(context.typeOf(columns[1]).nullable, isTrue);
    }

    test('unaliased columns, unaliased tables', () {
      testWith('SELECT sender, id FROM messages '
          'LEFT JOIN users ON id = sender');
    });

    test('unaliased columns, aliased tables', () {
      testWith('SELECT sender, id FROM messages m '
          'LEFT JOIN users u ON id = sender');
    });

    test('aliased columns, unaliased tables', () {
      testWith('SELECT messages.sender, users.id FROM messages '
          'LEFT JOIN users ON id = sender');
    });

    test('aliased columns, aliased tables', () {
      testWith('SELECT m.*, u.* FROM messages m '
          'LEFT JOIN users u ON u.id = m.sender');
    });

    test('single star, aliased tables', () {
      testWith('SELECT * FROM messages m '
          'LEFT JOIN users u ON u.id = m.sender');
    });

    test('single star, unaliased tables', () {
      testWith('SELECT * FROM messages '
          'LEFT JOIN users ON id = sender');
    });
  });

  group('join analysis keeps column non-nullable', () {
    void testWith(String sql) {
      final engine = SqlEngine(EngineOptions(version: SqliteVersion.v3_35))
        ..registerTableFromSql('''
      CREATE TABLE users (
        id INTEGER NOT NULL PRIMARY KEY
      );
    ''');

      final result = engine.analyze(sql);
      expect(result.errors, isEmpty);

      final root = result.root as StatementReturningColumns;

      expect(
        root.returnedResultSet!.resolvedColumns!
            .map((e) => result.typeOf(e).type),
        everyElement(
            isA<ResolvedType>().having((e) => e.nullable, 'nullable', isFalse)),
      );
    }

    test('for reference to table in INSERT', () {
      testWith('INSERT INTO users VALUES (?) RETURNING id;');
    });

    test('for reference to table in UPDATE', () {
      testWith('UPDATE users SET id = id + 1 RETURNING id;');
    });

    test('for reference to table in DELETE', () {
      testWith('DELETE FROM users RETURNING id;');
    });
  });

  test('resolves column in foreign key declaration', () {
    final engine = SqlEngine()..registerTableFromSql('''
CREATE TABLE points (
  id INTEGER NOT NULL PRIMARY KEY,
  lat REAL NOT NULL,
  long REAL NOT NULL
);
''');

    final parseResult = engine.parse('''
CREATE TABLE routes (
  route_id INTEGER NOT NULL PRIMARY KEY,
  "from" INTEGER NOT NULL REFERENCES points (id),
  "to" INTEGER NOT NULL REFERENCES points (id)
);
''');
    final table = const SchemaFromCreateTable()
        .read(parseResult.rootNode as CreateTableStatement);
    engine.registerTable(table);

    final result = engine.analyzeParsed(parseResult);

    result.expectNoError();

    final createTable = result.root as CreateTableStatement;
    final fromReference =
        createTable.columns[1].constraints[1] as ForeignKeyColumnConstraint;
    final fromReferenced =
        fromReference.clause.columnNames.single.resolvedColumn;

    expect(fromReferenced, isNotNull);
    expect(fromReferenced!.source.containingSet,
        result.rootScope.knownTables['points']);
  });
}
