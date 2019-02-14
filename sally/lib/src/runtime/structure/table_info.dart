import 'package:sally/sally.dart';
import 'package:sally/src/runtime/expressions/variables.dart';

/// Base class for generated classes.
abstract class TableInfo<TableDsl, DataClass> {
  TableDsl get asDslTable;

  /// The primary key of this table. Can be null if no custom primary key has
  /// been specified
  Set<GeneratedColumn> get $primaryKey => null;

  /// The table name in the sql table
  String get $tableName;
  List<GeneratedColumn> get $columns;

  /// Validates that the given entity can be inserted into this table, meaning
  /// that it respects all constraints (nullability, text length, etc.).
  /// During insertion mode, fields that have a default value or are
  /// auto-incrementing are allowed to be null as they will be set by sqlite.
  bool validateIntegrity(DataClass instance, bool isInserting) => null;

  /// Maps the given data class into a map that can be inserted into sql. The
  /// keys should represent the column name in sql, the values the corresponding
  /// values of the field.
  Map<String, Variable> entityToSql(DataClass instance);

  DataClass map(Map<String, dynamic> data);
}
