import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

void main() {
  test('regression test for #917', () {
    // Test for https://github.com/simolus3/moor/issues/917
    final engine = SqlEngine()
      ..registerTableFromSql('CREATE TABLE Shops (id INTEGER);')
      ..registerTableFromSql(
          'CREATE TABLE Sales (shop_id INTEGER, date INTEGER, amount REAL);');

    final result = engine.analyze('''
      SELECT
          Shops.id,
          SalesYesterday.amount AS amount_yesterday,
          SalesToday.amount AS amount_today
      FROM Sales AS SalesYesterday,
      (
          SELECT SalesToday.amount AS amount, SalesToday.shop_id AS shop_id
          FROM Sales AS SalesToday
          LEFT JOIN Shops ON SalesToday.shop_id = Shops.id
          WHERE SalesToday.date = 8
      ) AS SalesToday
      INNER JOIN Shops
          ON (SalesYesterday.shop_id = Shops.id)
          AND (SalesToday.shop_id = Shops.id)
      WHERE SalesYesterday.date = 9
      ORDER BY Shops.id;
      ''');

    expect(result.errors, isEmpty);
  });

  test('regression test for #1188', () {
    // Test for https://github.com/simolus3/moor/issues/1188
    final engine = SqlEngine(EngineOptions(useMoorExtensions: true))
      ..registerTableFromSql('''
        CREATE TABLE IF NOT EXISTS "employees" (
     	    "id" INTEGER NOT NULL PRIMARY KEY,
     	    "name" TEXT NOT NULL UNIQUE,
     	    "manager_id" INTEGER
     	  );
      ''')
      ..registerTableFromSql('''
        CREATE TABLE IF NOT EXISTS "employee_notes" (
          "employee_id"	INTEGER NOT NULL PRIMARY KEY,
          "note" TEXT
        );
      ''');

    final result = engine.analyze('''
      WITH RECURSIVE
      employeeHierarchy(id, name, manager_id) AS (
        SELECT id, 
               name,
               manager_id
          FROM employees
          WHERE manager_id IS NULL
          UNION ALL
        SELECT e.id, 
               e.name,
               e.manager_id
          FROM employees e
          JOIN employeeHierarchy ON e.manager_id = employeeHierarchy.id
      )
      SELECT e.id, 
            e.name,
            e.manager_id,
            n.note
        FROM employeeHierarchy e
        LEFT OUTER JOIN
            employee_notes n ON e.id = n.employee_id
      ORDER BY e.id;
    ''');

    final select = result.root as SelectStatement;
    final columns = select.resolvedColumns!;

    expect(columns.map((e) => e.name), ['id', 'name', 'manager_id', 'note']);
    expect(columns.map((e) => result.typeOf(e).nullable),
        [false, false, true, true]);
  });
}

extension on SqlEngine {
  void registerTableFromSql(String createTable) {
    final stmt = parse(createTable).rootNode as CreateTableStatement;
    registerTable(schemaReader.read(stmt));
  }
}
