import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/utils/ast_equality.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test('parses create table statements with a previous malformed inport', () {
    final file = parseMoor('''
import ;
CREATE TABLE foo (name TEXT);
    ''');

    expect(
        file.childNodes, contains(const TypeMatcher<CreateTableStatement>()));
  });

  test('recovers from parsing errors in column definition', () {
    final file = parseMoor('''
CREATE TABLE foo (
  id INTEGER PRIMARY,
  name TEXT NOT NULL 
);
    ''');

    final stmt = file.childNodes.single as CreateTableStatement;
    enforceEqual(
      stmt,
      CreateTableStatement(
        tableName: 'foo',
        columns: [
          // id column can't be parsed because of the missing KEY
          ColumnDefinition(
            columnName: 'name',
            typeName: 'TEXT',
            constraints: [NotNull(null)],
          ),
        ],
      ),
    );
  });

  test('parses trailing comma with error', () {
    final engine = SqlEngine(EngineOptions(useMoorExtensions: true));

    final result = engine.parseMoorFile('''
CREATE TABLE foo (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
);
    ''');

    expect(result.errors, hasLength(1));

    enforceEqual(
      result.rootNode.childNodes.single,
      CreateTableStatement(
        tableName: 'foo',
        columns: [
          ColumnDefinition(
            columnName: 'id',
            typeName: 'INTEGER',
            constraints: [PrimaryKeyColumn(null)],
          ),
          ColumnDefinition(
            columnName: 'name',
            typeName: 'TEXT',
            constraints: [NotNull(null)],
          ),
        ],
      ),
    );
  });
}
