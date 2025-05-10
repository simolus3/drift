import 'package:drift/dialect/sqlite.dart';
import 'package:drift/drift.dart';
import 'package:test/test.dart';

void main() {
  const dialect = SqliteDialect();

  test('int column writes AUTOINCREMENT constraint', () {
    final column = TableColumn<int>(
      name: 'foo',
      isNullable: false,
      type: BuiltinDriftType.int,
      constraints: () => [ColumnPrimaryKeyConstraint(isAutoIncrementing: true)],
    );

    final compiler = dialect.createCompiler()..addTableColumnDefinition(column);
    expect(compiler.statement.sql,
        equals('"foo" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT'));
  });

  test('int column writes PRIMARY KEY constraint', () {
    final column = TableColumn<int>(
      name: 'foo',
      isNullable: false,
      type: BuiltinDriftType.int,
      constraints: () =>
          [ColumnPrimaryKeyConstraint(isAutoIncrementing: false)],
    );

    final compiler = dialect.createCompiler()..addTableColumnDefinition(column);
    expect(
        compiler.statement.sql, equals('"foo" INTEGER NOT NULL PRIMARY KEY'));
  });

  test('can add custom constraints', () {
    final column = TableColumn<int>(
      name: 'foo',
      isNullable: false,
      type: BuiltinDriftType.int,
      constraints: () => [
        ColumnPrimaryKeyConstraint(isAutoIncrementing: false),
        ColumnConstraint.customSql('custom')
      ],
    );

    final compiler = dialect.createCompiler()..addTableColumnDefinition(column);
    expect(compiler.statement.sql, equals('"foo" INTEGER PRIMARY KEY custom'));
  });
}
