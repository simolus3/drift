import 'package:sally_generator/src/model/specified_column.dart';
import 'package:analyzer/dart/element/element.dart';

class SpecifiedTable {
  final ClassElement fromClass;
  final List<SpecifiedColumn> columns;
  final String sqlName;
  final String dartTypeName;

  const SpecifiedTable(
      {this.fromClass, this.columns, this.sqlName, this.dartTypeName});
}
