import 'package:moor_generator/src/model/specified_column.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:recase/recase.dart';

/// A parsed table, declared in code by extending `Table` and referencing that
/// table in `@UseMoor` or `@UseDao`.
class SpecifiedTable {
  /// The [ClassElement] for the class that declares this table.
  final ClassElement fromClass;

  /// The columns declared in this table.
  final List<SpecifiedColumn> columns;

  /// The name of this table when stored in the database
  final String sqlName;

  /// The name for the data class associated with this table
  final String dartTypeName;

  String get tableFieldName => ReCase(fromClass.name).camelCase;
  String get tableInfoName => tableInfoNameForTableClass(fromClass);
  String get updateCompanionName => _updateCompanionName(fromClass);

  /// The set of primary keys, if they have been explicitly defined by
  /// overriding `primaryKey` in the table class. `null` if the primary key has
  /// not been defined that way.
  final Set<SpecifiedColumn> primaryKey;

  const SpecifiedTable(
      {this.fromClass,
      this.columns,
      this.sqlName,
      this.dartTypeName,
      this.primaryKey});
}

String tableInfoNameForTableClass(ClassElement fromClass) =>
    '\$${fromClass.name}Table';

String _updateCompanionName(ClassElement fromClass) =>
    '${fromClass.name}Companion';
