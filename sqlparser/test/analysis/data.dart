import 'package:sqlparser/sqlparser.dart';

final id = TableColumn('id', const ResolvedType(type: BasicType.int));
final content =
    TableColumn('content', const ResolvedType(type: BasicType.text));

final demoTable = Table(
  name: 'demo',
  resolvedColumns: [id, content],
);

final anotherId = TableColumn('id', const ResolvedType(type: BasicType.int));
final dateTime = TableColumn(
    'date', const ResolvedType(type: BasicType.int, hint: IsDateTime()));

final anotherTable = Table(
  name: 'table',
  resolvedColumns: [anotherId, dateTime],
);
