import 'package:sally/sally.dart';

/// Base class for generated classes.
abstract class TableInfo<TableDsl, DataClass> {
  TableDsl get asDslTable;

  /// The table name in the sql table
  String get $tableName;
  List<Column> get $columns;

  DataClass map(Map<String, dynamic> data);
}
