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

/// The DBSTAT virtual table is a read-only eponymous virtual table that returns
/// information about the amount of disk space used to store the content of an
/// SQLite database
Table get dbstat {
  /// Name of table or index
  final name = TableColumn('name', const ResolvedType(type: BasicType.text));

  /// Path to page from root
  final path = TableColumn('path', const ResolvedType(type: BasicType.text));

  /// Page number, or page count
  final pageno = TableColumn('pageno', const ResolvedType(type: BasicType.int));

  /// 'internal', 'leaf', 'overflow', or NULL
  final pagetype =
      TableColumn('pagetype', const ResolvedType(type: BasicType.text));

  /// Cells on page (0 for overflow pages)
  final ncell = TableColumn('ncell', const ResolvedType(type: BasicType.int));

  /// Bytes of payload on this page or btree
  final payload =
      TableColumn('payload', const ResolvedType(type: BasicType.int));

  /// Bytes of unused space on this page or btree
  final unused = TableColumn('unused', const ResolvedType(type: BasicType.int));

  /// Bytes of unused space on this page or btree
  final mxPayload =
      TableColumn('mx_payload', const ResolvedType(type: BasicType.int));

  /// Byte offset of the page in the database file
  final pgoffset =
      TableColumn('pgoffset', const ResolvedType(type: BasicType.int));

  /// Size of the page, in bytes
  final pgsize = TableColumn('pgsize', const ResolvedType(type: BasicType.int));

  /// Database schema being analyzed
  final schema = TableColumn('schema', const ResolvedType(type: BasicType.text),
      isHidden: true);

  /// True to enable aggregate mode
  final aggregate = TableColumn(
      'aggregate', const ResolvedType(type: BasicType.int),
      isHidden: true);

  return Table(
    name: 'dbstat',
    isVirtual: true,
    resolvedColumns: [
      name,
      path,
      pageno,
      pagetype,
      ncell,
      payload,
      unused,
      mxPayload,
      pgoffset,
      pgsize,
      schema,
      aggregate,
    ],
  );
}
