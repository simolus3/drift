import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test('rename', () {
    testStatement(
      'ALTER TABLE foo RENAME TO bar',
      AlterTableStatement(TableReference('foo'), RenameTo('bar')),
    );

    testStatement(
      'ALTER TABLE s.foo RENAME TO bar',
      AlterTableStatement(
        TableReference(schemaName: 's', 'foo'),
        RenameTo('bar'),
      ),
    );
  });

  test('rename column', () {
    testStatement(
      'ALTER TABLE foo RENAME bar TO baz',
      AlterTableStatement(
        TableReference('foo'),
        RenameColumnTo(Reference(columnName: 'bar'), 'baz'),
      ),
    );

    testStatement(
      'ALTER TABLE foo RENAME COLUMN bar TO baz',
      AlterTableStatement(
        TableReference('foo'),
        RenameColumnTo(Reference(columnName: 'bar'), 'baz'),
      ),
    );
  });

  test('add column', () {
    testStatement(
      'ALTER TABLE foo ADD COLUMN bar TEXT',
      AlterTableStatement(
        TableReference('foo'),
        AddColumn(ColumnDefinition(columnName: 'bar', typeName: 'TEXT')),
      ),
    );

    testStatement(
      'ALTER TABLE foo ADD bar TEXT',
      AlterTableStatement(
        TableReference('foo'),
        AddColumn(ColumnDefinition(columnName: 'bar', typeName: 'TEXT')),
      ),
    );
  });

  test('drop column', () {
    testStatement(
      'ALTER TABLE foo DROP bar',
      AlterTableStatement(
        TableReference('foo'),
        DropColumn(Reference(columnName: 'bar')),
      ),
    );

    testStatement(
      'ALTER TABLE foo DROP COLUMN bar',
      AlterTableStatement(
        TableReference('foo'),
        DropColumn(Reference(columnName: 'bar')),
      ),
    );
  });

  test('alter column', () {
    testStatement(
      'ALTER TABLE foo ALTER COLUMN bar SET NOT NULL',
      AlterTableStatement(
        TableReference('foo'),
        AlterColumn(columnName: 'bar', instruction: AlterColumnSetNotNull()),
      ),
    );

    testStatement(
      'ALTER TABLE foo ALTER COLUMN bar DROP NOT NULL',
      AlterTableStatement(
        TableReference('foo'),
        AlterColumn(columnName: 'bar', instruction: AlterColumnDropNotNull()),
      ),
    );
  });

  test('add constraint', () {
    testStatement(
      'ALTER TABLE foo ADD CONSTRAINT bar CHECK (foo >= 18);',
      AlterTableStatement(
        TableReference('foo'),
        AddConstraint(
          checkTable: CheckTable(
            "bar",
            BinaryExpression(
              Reference(columnName: 'foo'),
              token(TokenType.moreEqual),
              NumericLiteral(18),
            ),
          ),
        ),
      ),
    );

    testStatement(
      'ALTER TABLE foo ADD CHECK (foo != 18);',
      AlterTableStatement(
        TableReference('foo'),
        AddConstraint(
          checkTable: CheckTable(
            null,
            BinaryExpression(
              Reference(columnName: 'foo'),
              token(TokenType.exclamationEqual),
              NumericLiteral(18),
            ),
          ),
        ),
      ),
    );
  });

  test('DROP CONSTRAINT', () {
    testStatement(
      'ALTER TABLE foo DROP CONSTRAINT bar;',
      AlterTableStatement(TableReference('foo'), DropConstraint(name: 'bar')),
    );
  });
}
