import 'package:moor_generator/src/model/specified_column.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:moor_generator/src/model/used_type_converter.dart';
import 'package:recase/recase.dart';

/// A parsed table, declared in code by extending `Table` and referencing that
/// table in `@UseMoor` or `@UseDao`.
class SpecifiedTable {
  /// The [ClassElement] for the class that declares this table or null if
  /// the table was inferred from a `CREATE TABLE` statement.
  final ClassElement fromClass;

  /// If [fromClass] is null, another source to use when determining the name
  /// of this table in generated Dart code.
  final String _overriddenName;

  /// Whether this table was created from an `ALTER TABLE` statement instead of
  /// a Dart class.
  bool get isFromSql => _overriddenName != null;

  String get _baseName => _overriddenName ?? fromClass.name;

  /// The columns declared in this table.
  final List<SpecifiedColumn> columns;

  /// The name of this table when stored in the database
  final String sqlName;

  /// The name for the data class associated with this table
  final String dartTypeName;

  String get tableFieldName => _dbFieldName(_baseName);
  String get tableInfoName {
    // if this table was parsed from sql, a user might want to refer to it
    // directly because there is no user defined parent class.
    // So, turn CREATE TABLE users into something called "Users" instead of
    // "$UsersTable".
    if (_overriddenName != null) {
      return _overriddenName;
    }
    return tableInfoNameForTableClass(_baseName);
  }

  String get updateCompanionName => _updateCompanionName(_baseName);

  /// The set of primary keys, if they have been explicitly defined by
  /// overriding `primaryKey` in the table class. `null` if the primary key has
  /// not been defined that way.
  final Set<SpecifiedColumn> primaryKey;

  /// When non-null, the generated table class will override the `withoutRowId`
  /// getter on the table class with this value.
  final bool overrideWithoutRowId;

  /// When non-null, the generated table class will override the
  /// `dontWriteConstraint` getter on the table class with this value.
  final bool overrideDontWriteConstraints;

  /// When non-null, the generated table class will override the
  /// `customConstraints` getter in the table class with this value.
  final List<String> overrideTableConstraints;

  /// The set of tables referenced somewhere in the declaration of this table,
  /// for instance by using a `REFERENCES` column constraint.
  final Set<SpecifiedTable> references = {};

  SpecifiedTable(
      {this.fromClass,
      this.columns,
      this.sqlName,
      this.dartTypeName,
      this.primaryKey,
      String overriddenName,
      this.overrideWithoutRowId,
      this.overrideTableConstraints,
      this.overrideDontWriteConstraints})
      : _overriddenName = overriddenName;

  /// Finds all type converters used in this tables.
  Iterable<UsedTypeConverter> get converters =>
      columns.map((c) => c.typeConverter).where((t) => t != null);

  String get displayName {
    if (isFromSql) {
      return sqlName;
    } else {
      return fromClass.displayName;
    }
  }

  @override
  String toString() {
    return 'SpecifiedTable: $displayName';
  }
}

String _dbFieldName(String className) => ReCase(className).camelCase;

String tableInfoNameForTableClass(String className) => '\$${className}Table';

String _updateCompanionName(String className) => '${className}Companion';
