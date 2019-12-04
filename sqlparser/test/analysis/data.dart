import 'package:sqlparser/sqlparser.dart';

final TableColumn id = TableColumn(
  'id',
  const ResolvedType(type: BasicType.int),
  definition: ColumnDefinition(
    columnName: 'id',
    typeName: 'INTEGER',
    constraints: [PrimaryKeyColumn(null)],
  ),
);
final TableColumn content =
    TableColumn('content', const ResolvedType(type: BasicType.text));

final Table demoTable = Table(
  name: 'demo',
  resolvedColumns: [id, content],
);

final TableColumn anotherId =
    TableColumn('id', const ResolvedType(type: BasicType.int));
final TableColumn dateTime = TableColumn(
    'date', const ResolvedType(type: BasicType.int, hint: IsDateTime()));

final Table anotherTable = Table(
  name: 'tbl',
  resolvedColumns: [anotherId, dateTime],
);
