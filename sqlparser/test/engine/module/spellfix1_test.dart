import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

final _spellfixOptions =
    EngineOptions(enabledExtensions: const [Spellfix1Extension()]);

void main() {
  final engine = SqlEngine(_spellfixOptions);
  test('creating spellfix1 table', () {
    final result = engine.analyze('CREATE VIRTUAL TABLE demo USING spellfix1;');

    final table = const SchemaFromCreateTable()
        .read(result.root as TableInducingStatement);

    expect(table.name, 'demo');
    final columns = table.resultColumns;
    expect(columns, hasLength(6));
  });

  group('engine analyze spellfix1', () {
    late SqlEngine engine;
    setUp(() {
      engine = SqlEngine(_spellfixOptions);
      final fts5Result =
          engine.analyze('CREATE VIRTUAL TABLE demo USING spellfix1;');
      engine.registerTable(const SchemaFromCreateTable()
          .read(fts5Result.root as TableInducingStatement));
    });

    test('ignore hidden columns in result', () {
      final result =
          engine.analyze('SELECT * FROM demo WHERE word MATCH \'none\'');
      expect(result.errors, isEmpty);

      final select = result.root as SelectStatement;
      expect(select.resolvedColumns, hasLength(6));
    });

    test('accepts hidden columns in query', () {
      final result = engine
          .analyze('SELECT * FROM demo WHERE word MATCH \'none\' AND top=3');
      expect(result.errors, isEmpty);
    });

    test('consideres hidden columns', () {
      final result = engine.analyze(
          'SELECT * FROM demo WHERE word MATCH \'none\' AND noneexistent=3');
      expect(result.errors, hasLength(1));
    });
  });
}
