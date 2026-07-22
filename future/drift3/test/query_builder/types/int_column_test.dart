import 'package:drift3/drift.dart';
import 'package:drift_sqlite/drift_sqlite.dart';
import 'package:test/test.dart';

void main() {
  const dialect = SqliteDialect.withOptions();

  test('int column writes AUTOINCREMENT constraint', () {
    final column = TableColumn<int>(
      name: 'foo',
      sqlType: BuiltinDriftType.int,

      constraints: () => const [
        ColumnNotNullConstraint(),
        ColumnPrimaryKeyConstraint(isAutoIncrementing: true),
      ],
    );

    final compiler = dialect.createCompiler()..addTableColumnDefinition(column);
    expect(
      compiler.statement.buffer.toString(),
      equals('"foo" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT'),
    );
  });

  test('int column writes PRIMARY KEY constraint', () {
    final column = TableColumn<int>(
      name: 'foo',
      sqlType: BuiltinDriftType.int,
      constraints: () => const [
        ColumnNotNullConstraint(),
        ColumnPrimaryKeyConstraint(isAutoIncrementing: false),
      ],
    );

    final compiler = dialect.createCompiler()..addTableColumnDefinition(column);
    expect(
      compiler.statement.buffer.toString(),
      equals('"foo" INTEGER NOT NULL PRIMARY KEY'),
    );
  });

  test('can add custom constraints', () {
    final column = TableColumn<int>(
      name: 'foo',
      sqlType: BuiltinDriftType.int,
      constraints: () => [
        ColumnPrimaryKeyConstraint(isAutoIncrementing: false),
        ColumnConstraint.customSql('custom'),
      ],
    );

    final compiler = dialect.createCompiler()..addTableColumnDefinition(column);
    expect(
      compiler.statement.buffer.toString(),
      equals('"foo" INTEGER PRIMARY KEY custom'),
    );
  });
}
