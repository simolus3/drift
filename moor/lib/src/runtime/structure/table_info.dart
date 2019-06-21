import 'package:moor/moor.dart';
import 'package:moor/src/runtime/expressions/variables.dart';

/// Base class for generated classes. [TableDsl] is the type specified by the
/// user that extends [Table], [D] is the type of the data class
/// generated from the table.
mixin TableInfo<TableDsl extends Table, D extends DataClass> {
  /// Type system sugar. Implementations are likely to inherit from both
  /// [TableInfo] and [TableDsl] and can thus just return their instance.
  TableDsl get asDslTable;

  /// The primary key of this table. Can be null or empty if no custom primary
  /// key has been specified.
  Set<GeneratedColumn> get $primaryKey => null;

  /// The table name in the sql table. This can be an alias for the actual table
  /// name. See [actualTableName] for a table name that is not aliased.
  String get $tableName;

  /// The name of the table in the database. Unless [$tableName], this can not
  /// be aliased.
  String get actualTableName;

  /// The table name, optionally suffixed with the alias if one exists. This
  /// can be used in select statements, as it returns something like "users u"
  /// for a table called users that has been aliased as "u".
  String get tableWithAlias {
    if ($tableName == actualTableName) {
      return actualTableName;
    } else {
      return '$actualTableName ${$tableName}';
    }
  }

  List<GeneratedColumn> get $columns;

  /// Validates that the given entity can be inserted into this table, meaning
  /// that it respects all constraints (nullability, text length, etc.).
  VerificationContext validateIntegrity(covariant UpdateCompanion<D> instance,
      {bool isInserting = false});

  /// Maps the given update companion to a [Map] that can be inserted into sql.
  /// The keys should represent the column name in sql, the values the
  /// corresponding values of the field. All fields of the [instance] which are
  /// present will be written, absent fields will be omitted.
  Map<String, Variable> entityToSql(covariant UpdateCompanion<D> instance);

  /// Maps the given row returned by the database into the fitting data class.
  D map(Map<String, dynamic> data, {String tablePrefix});

  TableInfo<TableDsl, D> createAlias(String alias);
}
