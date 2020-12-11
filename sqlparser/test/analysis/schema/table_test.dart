import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

void main() {
  group('finds columns', () {
    final engine = SqlEngine();
    const schemaParser = SchemaFromCreateTable();

    Column? findWith(String createTbl, String columnName) {
      final stmt = engine.parse(createTbl).rootNode as CreateTableStatement;
      final table = schemaParser.read(stmt);
      return table.findColumn(columnName);
    }

    test('when declared in table', () {
      expect(findWith('CREATE TABLE x (__rowid__ VARCHAR)', '__rowid__'),
          isA<TableColumn>());
    });

    test('when alias to rowid', () {
      final column = findWith('CREATE TABLE x (id INTEGER PRIMARY KEY)', 'oid');
      expect(column?.name, 'id');
      expect(column, isA<TableColumn>());
    });

    test('when virtual rowid column', () {
      final column = findWith('CREATE TABLE x (id VARCHAR)', 'oid');
      expect(column, isA<RowId>());
    });

    test('when not found', () {
      final column = findWith(
          'CREATE TABLE x (id INTEGER PRIMARY KEY) WITHOUT ROWID', 'oid');
      expect(column, isNull);
    });
  });
}
