import 'package:sqlparser/sqlparser.dart';

class RTreeExtension implements Extension {
  const RTreeExtension();

  @override
  void register(SqlEngine engine) {
    engine.registerModule(_RTreeModule());
  }
}

class _RTreeModule extends Module {
  _RTreeModule() : super('rtree');

  @override
  Table parseTable(CreateVirtualTableStatement stmt) {
    final columnNames = stmt.argumentContent;

    if (columnNames.length < 3 || columnNames.length > 11) {
      throw ArgumentError(
          'An rtree virtual table is supposed to have between 3 and 11 columns');
    }

    if (columnNames.length.isEven) {
      throw ArgumentError(
          'The rtree has not been initialized with a proper dimension. '
          'Required is an index, follwoed by a even number of min/max pairs');
    }

    return Table(name: stmt.tableName, resolvedColumns: [
      for (final columnName in columnNames)
        //First column is always an integer primary key
        //followed by n floating point values
        (columnName == columnNames.first)
            ? TableColumn(columnName, const ResolvedType(type: BasicType.int))
            : TableColumn(columnName, const ResolvedType(type: BasicType.real))
    ]);
  }
}
