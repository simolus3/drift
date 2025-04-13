import 'package:drift/drift.dart';

final class TestTable extends Table
    with ResultSet<DriftRow, TestTable>
    implements GeneratedTable<DriftRow, TestTable> {
  @override
  final String? alias;

  @override
  final String entityName;

  @override
  final List<TableColumn> columns;

  TestTable(this.entityName, this.columns, {this.alias}) {
    for (final column in columns) {
      column.owningResultSet = this;
    }
  }

  @override
  TestTable asSelfType() => this;

  @override
  DriftRow? Function(DriftRow p1) createMapperFromPositions(
      List<ColumnPosition> positions) {
    return (row) => row;
  }

  @override
  TestTable withAlias(String alias) {
    return TestTable(entityName, columns, alias: alias);
  }
}
