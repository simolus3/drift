import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/utils/ast_equality.dart';
import 'package:test/test.dart';

const content = r'''
import 'other.dart';
import 'another.moor';

CREATE TABLE tbl (
  id INT NOT NULL PRIMARY KEY AUTOINCREMENT,
  -- this is a single-line comment
  place VARCHAR REFERENCES other(location)
) AS RowName

all: SELECT /* COUNT(*), */ * FROM tbl WHERE $predicate;
''';

void main() {
  test('parses moor files', () {
    final parsed = SqlEngine(useMoorExtensions: true).parseMoorFile(content);
    final file = parsed.rootNode;

    enforceEqual(
      file,
      MoorFile([
        ImportStatement('other.dart'),
        ImportStatement('another.moor'),
        CreateTableStatement(
          tableName: 'tbl',
          columns: [
            ColumnDefinition(
              columnName: 'id',
              typeName: 'INT',
              constraints: [
                NotNull(null),
                PrimaryKeyColumn(null, autoIncrement: true),
              ],
            ),
            ColumnDefinition(
              columnName: 'place',
              typeName: 'VARCHAR',
              constraints: [
                ForeignKeyColumnConstraint(
                  null,
                  ForeignKeyClause(
                    foreignTable: TableReference('other', null),
                    columnNames: [
                      Reference(columnName: 'location'),
                    ],
                  ),
                ),
              ],
            ),
          ],
          overriddenDataClassName: 'RowName',
        ),
        DeclaredStatement(
          'all',
          SelectStatement(
            columns: [StarResultColumn(null)],
            from: [TableReference('tbl', null)],
            where: DartExpressionPlaceholder(name: 'predicate'),
          ),
        ),
      ]),
    );
  });
}
