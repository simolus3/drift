import 'package:sqlparser/sqlparser.dart';

final id = TableColumn('id', const ResolvedType(type: BasicType.int));
final content =
    TableColumn('content', const ResolvedType(type: BasicType.text));

final demoTable = Table(
  name: 'demo',
  resolvedColumns: [id, content],
);
