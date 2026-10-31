import 'package:drift3_preview/drift.dart';
import 'package:drift_sqlite/drift_sqlite.dart';
import 'package:test/test.dart';

void main() {
  const dialect = SqliteDialect.withOptions();

  test('foreign key writes ON UPDATE and ON DELETE', () {
    final column = TableColumn<int>(
      name: 'foo',
      sqlType: .int,
      constraints: () => const [
        ColumnForeignKeyConstraint(
          otherTableName: 'parents',
          otherColumnName: 'id',
          onUpdate: ReferenceAction.restrict,
          onDelete: ReferenceAction.cascade,
        ),
      ],
    );

    final compiler = dialect.createCompiler()..addTableColumnDefinition(column);
    expect(
      compiler.statement.buffer.toString(),
      equals(
        '"foo" INTEGER REFERENCES parents (id) ON UPDATE RESTRICT ON DELETE CASCADE',
      ),
    );
  });
}
