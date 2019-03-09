import 'package:moor_generator/src/model/specified_column.dart';
import 'package:analyzer/dart/element/element.dart';

class SpecifiedTable {
  final ClassElement fromClass;
  final List<SpecifiedColumn> columns;
  final String sqlName;

  /// The name for the data class associated with this table
  final String dartTypeName;

  String get tableInfoName => tableInfoNameForTableClass(fromClass);

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
