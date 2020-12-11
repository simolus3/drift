import 'package:sqlparser/src/utils/ast_equality.dart';
import 'package:test/test.dart';
import 'package:sqlparser/sqlparser.dart';

import '../parser/utils.dart';
import 'data.dart';

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

    expect((firstColumn.expression as Reference).resolved, id);
    expect((secondColumn.expression as Reference).resolved, content);
    expect(from.resolved, demoTable);

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

  test("resolved columns don't include moor nested results", () {
    final engine = SqlEngine(EngineOptions(useMoorExtensions: true))
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
      resolved.expression!,
      BinaryExpression(
        NumericLiteral(3, token(TokenType.numberLiteral)),
        token(TokenType.star),
        Reference(tableName: 'd', columnName: 'id'),
      ),
    );
  });

  test('resolves columns from nested results', () {
    final engine = SqlEngine(EngineOptions(useMoorExtensions: true))
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

  test('resolves sub-queries', () {
    final engine = SqlEngine()..registerTable(demoTable);

    final context = engine.analyze(
        'SELECT d.*, (SELECT id FROM demo WHERE id = d.id) FROM demo d;');

    expect(context.errors, isEmpty);
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

    final over = (column.expression as AggregateExpression).over!;

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
}
