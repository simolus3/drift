import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test('parses CREATE TABLE statement', () {
    testStatement(
      'CREATE TABLE \"sample_table\" ('
      'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, sample VARCHAR NULL)',
      CreateTableStatement(
        tableName: 'sample_table',
        columns: [
          ColumnDefinition(
            columnName: 'id',
            typeName: 'INTEGER',
            constraints: [
              NotNull(null),
              PrimaryKeyColumn(null, autoIncrement: true),
            ],
          ),
          ColumnDefinition(
            columnName: 'sample',
            typeName: 'VARCHAR',
            constraints: [
              NullColumnConstraint(null),
            ],
          ),
        ],
      ),
      driftMode: true,
    );
  });
}
