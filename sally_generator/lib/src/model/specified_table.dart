import 'package:sally_generator/src/model/specified_column.dart';
import 'package:analyzer/dart/element/element.dart';

class SpecifiedTable {
  final ClassElement fromClass;
  final List<SpecifiedColumn> columns;
  final String sqlName;

  /// The name for the data class associated with this table
  final String dartTypeName;

  String get tableInfoName => tableInfoNameForTableClass(fromClass);

  // todo support primary keys
  Set<SpecifiedColumn> get primaryKey => <SpecifiedColumn>{};

  const SpecifiedTable(
      {this.fromClass, this.columns, this.sqlName, this.dartTypeName});
}

String tableInfoNameForTableClass(ClassElement fromClass) => '\$${fromClass.name}Table';