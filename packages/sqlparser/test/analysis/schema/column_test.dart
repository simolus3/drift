import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

void main() {
  test('isAliasForRowId', () {
    final engine = SqlEngine();
    const schemaParser = SchemaFromCreateTable();

    final isAlias = {
      'CREATE TABLE x (id INTEGER PRIMARY KEY)': true,
      'CREATE TABLE x (id INTEGER PRIMARY KEY) WITHOUT ROWID': false,
      'CREATE TABLE x (id BIGINT PRIMARY KEY)': false,
      'CREATE TABLE x (id INTEGER PRIMARY KEY DESC)': false,
      'CREATE TABLE x (id INTEGER)': false,
      'CREATE TABLE x (id INTEGER, PRIMARY KEY (id))': true,
    };

    isAlias.forEach((createTblString, isAlias) {
      final parsed =
          engine.parse(createTblString).rootNode as CreateTableStatement;
      final table = schemaParser.read(parsed);

      expect(
        (table.findColumn('id') as TableColumn).isAliasForRowId(),
        isAlias,
        reason: '$createTblString: id is an alias? $isAlias',
      );
    });
  });
}
