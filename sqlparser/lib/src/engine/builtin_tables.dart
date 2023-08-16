import 'package:sqlparser/sqlparser.dart';

/// Constructs the "sqlite_sequence" table.
Table get sqliteSequence {
  final name = TableColumn('name', const ResolvedType(type: BasicType.text));
  final seq = TableColumn('seq', const ResolvedType(type: BasicType.int));

  return Table(name: 'sqlite_sequence', resolvedColumns: [name, seq]);
}

/// Constructs the "sqlite_master" table
Table get sqliteMaster {
  final type = TableColumn('type', const ResolvedType(type: BasicType.text));
  final name = TableColumn('name', const ResolvedType(type: BasicType.text));
  final tblName =
      TableColumn('tbl_name', const ResolvedType(type: BasicType.text));
  final rootPage =
      TableColumn('rootpage', const ResolvedType(type: BasicType.int));
  final sql = TableColumn('sql', const ResolvedType(type: BasicType.text));

  return Table(
    name: 'sqlite_master',
    resolvedColumns: [type, name, tblName, rootPage, sql],
  );
}

/// Constructs the "sqlite_schema" table, which is identical to "sqlite_master"
/// after sqlite version 3.33.0
Table get sqliteSchema {
  return Table(
    name: 'sqlite_schema',
    resolvedColumns: sqliteMaster.resolvedColumns,
  );
}
