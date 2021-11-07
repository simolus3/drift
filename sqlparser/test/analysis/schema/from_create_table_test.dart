import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../../common_data.dart';
import '../data.dart';

const _affinityTests = {
  'INT': BasicType.int,
  'INTEGER': BasicType.int,
  'TINYINT': BasicType.int,
  'SMALLINT': BasicType.int,
  'MEDIUMINT': BasicType.int,
  'BIGINT': BasicType.int,
  'UNISGNED BIG INT': BasicType.int,
  'INT2': BasicType.int,
  'INT8': BasicType.int,
  'CHARACTER(20)': BasicType.text,
  'CHARACTER(255)': BasicType.text,
  'VARYING CHARACTER(255)': BasicType.text,
  'NCHAR(55)': BasicType.text,
  'NATIVE CHARACTER(70)': BasicType.text,
  'NVARCHAR(100)': BasicType.text,
  'TEXT': BasicType.text,
  'CLOB': BasicType.text,
  'BLOB': BasicType.blob,
  null: BasicType.blob,
  'REAL': BasicType.real,
  'DOUBLE': BasicType.real,
  'DOUBLE PRECISION': BasicType.real,
  'FLOAT': BasicType.real,
  'NUMERIC': BasicType.real,
  'DECIMAL(10,5)': BasicType.real,
  'BOOLEAN': BasicType.real,
  'DATE': BasicType.real,
  'DATETIME': BasicType.real,
};

void main() {
  test('affinity from typename', () {
    const resolver = SchemaFromCreateTable();

    _affinityTests.forEach((key, value) {
      expect(resolver.columnAffinity(key), equals(value),
          reason: '$key should have $value affinity');
    });
  });

  test('export table structure', () {
    final engine = SqlEngine();
    final stmt = engine.parse(createTableStmt).rootNode;

    final table =
        const SchemaFromCreateTable().read(stmt as CreateTableStatement);

    expect(table.resolvedColumns.map((c) => c.name),
        ['id', 'email', 'score', 'display_name']);
    expect(table.resolvedColumns.map((c) => c.type), const [
      ResolvedType(type: BasicType.int),
      ResolvedType(type: BasicType.text),
      ResolvedType(type: BasicType.int),
      ResolvedType(type: BasicType.text, nullable: true),
    ]);

    expect(table.tableConstraints, hasLength(2));
  });

  test('reads isGenerated', () {
    final engine = SqlEngine();
    final stmt = engine.parse('''
      CREATE TABLE tbl (
        a TEXT,
        b TEXT GENERATED ALWAYS AS (UPPER(b))
      );
    ''').rootNode;

    final table =
        const SchemaFromCreateTable().read(stmt as CreateTableStatement);

    expect(
      table.findColumn('a'),
      isA<TableColumn>().having((e) => e.isGenerated, 'isGenerated', isFalse),
    );
    expect(
      table.findColumn('b'),
      isA<TableColumn>().having((e) => e.isGenerated, 'isGenerated', isTrue),
    );
  });

  test('supports booleans when moor extensions are enabled', () {
    final engine = SqlEngine(EngineOptions(useMoorExtensions: true));
    final stmt = engine.parse('''
    CREATE TABLE foo (
      a BOOL, b DATETIME, c DATE, d BOOLEAN NOT NULL
    )
    ''').rootNode;

    final table = const SchemaFromCreateTable(moorExtensions: true)
        .read(stmt as CreateTableStatement);
    expect(table.resolvedColumns.map((c) => c.type), const [
      ResolvedType(type: BasicType.int, hint: IsBoolean(), nullable: true),
      ResolvedType(type: BasicType.int, hint: IsDateTime(), nullable: true),
      ResolvedType(type: BasicType.int, hint: IsDateTime(), nullable: true),
      ResolvedType(type: BasicType.int, hint: IsBoolean(), nullable: false),
    ]);
  });

  group('can read views', () {
    View readView(String sql) {
      final engine = SqlEngine()..registerTable(demoTable);
      final context = engine.analyze(sql);
      expect(context.errors, isEmpty);

      final stmt = context.root as CreateViewStatement;
      return const SchemaFromCreateTable().readView(context, stmt);
    }

    test('without column names', () {
      final view = readView('CREATE VIEW my_view AS SELECT * FROM demo;');

      expect(view.name, 'my_view');
      expect(view.resolvedColumns.map((e) => e.name), ['id', 'content']);
      expect(
        view.resolvedColumns.map((e) => e.type!.type),
        [BasicType.int, BasicType.text],
      );
    });

    test('with custom column names', () {
      final view = readView(
          'CREATE VIEW another_view (foo, bar) AS SELECT * FROM demo;');

      expect(view.name, 'another_view');
      expect(view.resolvedColumns.map((e) => e.name), ['foo', 'bar']);
    });

    test('with WITH clause', () {
      final view = readView('CREATE VIEW my_view AS '
          'WITH foo AS (SELECT * FROM demo) SELECT * FROM foo;');

      expect(view.name, 'my_view');
      expect(view.resolvedColumns.map((e) => e.name), ['id', 'content']);
    });
  });

  test('can read columns without type name', () {
    final engine = SqlEngine();
    final stmt = engine.parse('CREATE TABLE foo (id);').rootNode;

    final table = engine.schemaReader.read(stmt as CreateTableStatement);
    expect(table.resolvedColumns.single.type.type, BasicType.blob);
  });

  test('aliases to rowid are non-nullable', () {
    final engine = SqlEngine();
    final stmt =
        engine.parse('CREATE TABLE foo (id INTEGER PRIMARY KEY);').rootNode;

    final table = engine.schemaReader.read(stmt as CreateTableStatement);
    expect(table.resolvedColumns.single.type,
        const ResolvedType(type: BasicType.int, nullable: false));
  });
}
