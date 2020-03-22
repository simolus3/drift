import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import 'utils.dart';

final _block = Block([
  UpdateStatement(table: TableReference('tbl'), set: [
    SetComponent(
      column: Reference(columnName: 'foo'),
      expression: Reference(columnName: 'bar'),
    ),
  ]),
  SelectStatement(
    columns: [StarResultColumn()],
    from: TableReference('tbl'),
  ),
]);

void main() {
  test('parses create trigger statements', () {
    const sql = '''
     CREATE TRIGGER IF NOT EXISTS my_trigger
       AFTER DELETE ON tbl
       FOR EACH ROW
       BEGIN
         UPDATE tbl SET foo = bar;
         SELECT * FROM tbl;
       END;
    ''';

    testStatement(
      sql,
      CreateTriggerStatement(
        ifNotExists: true,
        triggerName: 'my_trigger',
        mode: TriggerMode.after,
        target: const DeleteTarget(),
        onTable: TableReference('tbl'),
        action: _block,
      ),
    );
  });

  test('with INSTEAD OF mode and UPDATE', () {
    const sql = '''
     CREATE TRIGGER my_trigger
       INSTEAD OF UPDATE OF foo, bar ON tbl
       BEGIN
         UPDATE tbl SET foo = bar;
         SELECT * FROM tbl;
       END;
    ''';

    testStatement(
      sql,
      CreateTriggerStatement(
        triggerName: 'my_trigger',
        mode: TriggerMode.insteadOf,
        target: UpdateTarget([
          Reference(columnName: 'foo'),
          Reference(columnName: 'bar'),
        ]),
        onTable: TableReference('tbl'),
        action: _block,
      ),
    );
  });

  test('with BEFORE, INSERT and WHEN clause', () {
    const sql = '''
     CREATE TRIGGER my_trigger
       BEFORE INSERT ON tbl
       WHEN new.foo IS NULL
       BEGIN
         UPDATE tbl SET foo = bar;
         SELECT * FROM tbl;
       END;
    ''';

    testStatement(
      sql,
      CreateTriggerStatement(
        triggerName: 'my_trigger',
        mode: TriggerMode.before,
        target: const InsertTarget(),
        onTable: TableReference('tbl'),
        when: IsExpression(
          false,
          Reference(tableName: 'new', columnName: 'foo'),
          NullLiteral(token(TokenType.$null)),
        ),
        action: _block,
      ),
    );
  });
}
