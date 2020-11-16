import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

void main() {
  test('regression test for #917', () {
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
}

extension on SqlEngine {
  void registerTableFromSql(String createTable) {
    final stmt = parse(createTable).rootNode as CreateTableStatement;
    registerTable(schemaReader.read(stmt));
  }
}
