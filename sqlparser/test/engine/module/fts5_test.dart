import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

final _fts5Options = EngineOptions(enabledExtensions: const [Fts5Extension()]);

void main() {
  group('creating fts5 tables', () {
    final engine = SqlEngine(_fts5Options);

    test('can create fts5 tables', () {
      final result = engine.analyze('CREATE VIRTUAL TABLE foo USING '
          "fts5(bar , tokenize = 'porter ascii')");

      final table = const SchemaFromCreateTable()
          .read(result.root as TableInducingStatement);

      expect(table.name, 'foo');
      final columns = table.resultColumns;
      expect(columns, hasLength(1));
      expect(columns.single.name, 'bar');
    });

    test('handles the UNINDEXED column option', () {
      final result = engine
          .analyze('CREATE VIRTUAL TABLE foo USING fts5(bar, baz UNINDEXED)');

      final table = const SchemaFromCreateTable()
          .read(result.root as TableInducingStatement);

      expect(table.name, 'foo');
      expect(table.resultColumns.map((c) => c.name), ['bar', 'baz']);
    });
  });

  group('type inference for function calls', () {
    late SqlEngine engine;
    setUp(() {
      engine = SqlEngine(_fts5Options);
      // add an fts5 table for the following queries
      final fts5Result = engine.analyze('CREATE VIRTUAL TABLE foo USING '
          'fts5(bar, baz);');
      engine.registerTable(const SchemaFromCreateTable()
          .read(fts5Result.root as TableInducingStatement));
    });

    test('return type of bm25()', () {
      final result = engine
          .analyze('SELECT *, bm25(foo) AS b FROM foo WHERE foo MATCH \'\'');
      expect(result.errors, isEmpty);

      final select = result.root as SelectStatement;
      final column = select.resolvedColumns!.singleWhere((c) => c.name == 'b');
      expect(result.typeOf(column),
          const ResolveResult(ResolvedType(type: BasicType.real)));
    });

    test('return type of highlight()', () {
      final result =
          engine.analyze("SELECT *, highlight(foo, 0, '<b>', '</b>') AS b "
              "FROM foo WHERE foo MATCH ''");
      expect(result.errors, isEmpty);

      final select = result.root as SelectStatement;
      final column = select.resolvedColumns!.singleWhere((c) => c.name == 'b');
      expect(result.typeOf(column),
          const ResolveResult(ResolvedType(type: BasicType.text)));
    });

    test('return type of snippet()', () {
      final result = engine
          .analyze("SELECT *, snippet(foo, 0, '<b>', '</b>', '...', 20) AS b "
              "FROM foo WHERE foo MATCH ''");
      expect(result.errors, isEmpty);

      final select = result.root as SelectStatement;
      final column = select.resolvedColumns!.singleWhere((c) => c.name == 'b');
      expect(result.typeOf(column),
          const ResolveResult(ResolvedType(type: BasicType.text)));
    });
  });

  group('type inference for function arguments', () {
    late SqlEngine engine;
    setUp(() {
      engine = SqlEngine(_fts5Options);
      // add an fts5 table for the following queries
      final fts5Result = engine.analyze('CREATE VIRTUAL TABLE fts USING '
          'fts5(bar, baz);');
      engine.registerTable(const SchemaFromCreateTable()
          .read(fts5Result.root as TableInducingStatement));
    });

    void checkVarTypes(String sql, List<BasicType> expected) {
      final result = engine.analyze(sql);
      expect(result.errors, isEmpty);

      final foundVars = result.root.allDescendants.whereType<Variable>();

      expect(
        foundVars.map((Typeable t) => result.typeOf(t).type!.type),
        expected,
      );
    }

    test('for highlight()', () {
      checkVarTypes(
        'SELECT highlight(fts, ?, ?, ?) FROM fts;',
        [
          BasicType.int, // column index
          BasicType.text, // text before phrase match
          BasicType.text, // text after phrase match
        ],
      );
    });

    test('for snippet()', () {
      checkVarTypes(
        'SELECT snippet(fts, ?, ?, ?, ?, ?) FROM fts;',
        [
          BasicType.int, // column index
          BasicType.text, // text before match
          BasicType.text, // text after match
          BasicType.text, // text to add match isn't at start
          BasicType.int, // maximum number of tokens
        ],
      );
    });
  });

  group('error reporting', () {
    late SqlEngine engine;
    setUp(() {
      engine = SqlEngine(_fts5Options);
      // add an fts5 table for the following queries
      final fts5Result = engine.analyze('CREATE VIRTUAL TABLE foo USING '
          'fts5(bar, baz);');
      engine.registerTable(const SchemaFromCreateTable()
          .read(fts5Result.root as TableInducingStatement));

      final normalResult = engine.analyze('CREATE TABLE other (bar TEXT);');
      engine.registerTable(const SchemaFromCreateTable()
          .read(normalResult.root as TableInducingStatement));
    });

    Matcher hasMessage(Object msgMatcher) {
      return const TypeMatcher<AnalysisError>()
          .having((e) => e.message, 'message', msgMatcher);
    }

    test('when using star function parameters', () {
      final result = engine.analyze('SELECT bm25(*) FROM foo;');
      expect(result.errors, [hasMessage(contains('star parameter'))]);
    });

    test('when using a non-fts5 table as parameter', () {
      final result = engine.analyze('SELECT bm25(bar) FROM other');
      expect(result.errors, [hasMessage(contains('fts5 table name'))]);
    });

    test('when using the wrong number or arguments', () {
      final result = engine.analyze('SELECT highlight(foo, 3) FROM foo');
      expect(
        result.errors,
        [
          hasMessage(stringContainsInOrder(['highlight', '4', '2']))
        ],
      );
    });
  });

  test('does not include rank and table columns in result', () {
    final engine = SqlEngine(_fts5Options);
    final fts5Result = engine.analyze('CREATE VIRTUAL TABLE foo USING '
        'fts5(bar, baz);');
    engine.registerTable(const SchemaFromCreateTable()
        .read(fts5Result.root as TableInducingStatement));

    final selectResult = engine.analyze('SELECT * FROM foo;');
    final columns = (selectResult.root as SelectStatement).resolvedColumns;

    expect(columns, isNot(anyElement((Column c) => c.name == 'rank')));
    expect(columns, isNot(anyElement((Column c) => c.name == 'foo')));
  });
}
