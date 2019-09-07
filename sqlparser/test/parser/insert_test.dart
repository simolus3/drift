import 'package:test/test.dart';
import 'package:sqlparser/sqlparser.dart';

import 'utils.dart';

void main() {
  test('parses insert statements', () {
    testStatement(
      'INSERT OR REPLACE INTO tbl (a, b, c) VALUES (d, e, f)',
      InsertStatement(
        mode: InsertMode.insertOrReplace,
        table: TableReference('tbl', null),
        targetColumns: [
          Reference(columnName: 'a'),
          Reference(columnName: 'b'),
          Reference(columnName: 'c'),
        ],
        source: ValuesSource([
          TupleExpression(expressions: [
            Reference(columnName: 'd'),
            Reference(columnName: 'e'),
            Reference(columnName: 'f'),
          ]),
        ]),
      ),
    );
  });

  test('insert statement with default values', () {
    testStatement(
      'INSERT INTO tbl DEFAULT VALUES',
      InsertStatement(
        mode: InsertMode.insert,
        table: TableReference('tbl', null),
        targetColumns: const [],
        source: const DefaultValues(),
      ),
    );
  });

  test('insert statement with select as source', () {
    testStatement(
      'REPLACE INTO tbl SELECT * FROM tbl',
      InsertStatement(
        mode: InsertMode.replace,
        table: TableReference('tbl', null),
        targetColumns: const [],
        source: SelectInsertSource(
          SelectStatement(
            columns: [StarResultColumn(null)],
            from: [TableReference('tbl', null)],
          ),
        ),
      ),
    );
  });
}
