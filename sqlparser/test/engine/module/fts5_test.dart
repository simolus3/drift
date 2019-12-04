import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

void main() {
  test('can create fts5 tables', () {
    final engine = SqlEngine(enableFts5: true);
    final result = engine.analyze(
        "CREATE VIRTUAL TABLE foo USING fts5(bar , tokenize = 'porter ascii')");

    final table =
        SchemaFromCreateTable().read(result.root as TableInducingStatement);

    expect(table.name, 'foo');
    expect(table.resolvedColumns, hasLength(1));
    expect(table.resolvedColumns.single.name, 'bar');
  });

  test('handles the UNINDEXED column option', () {
    final engine = SqlEngine(enableFts5: true);
    final result = engine
        .analyze('CREATE VIRTUAL TABLE foo USING fts5(bar, baz UNINDEXED)');

    final table =
        SchemaFromCreateTable().read(result.root as TableInducingStatement);

    expect(table.name, 'foo');
    expect(table.resolvedColumns.map((c) => c.name), ['bar', 'baz']);
  });
}
