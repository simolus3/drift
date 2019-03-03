import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:sally_generator/src/model/specified_table.dart';

class SpecifiedDatabase {
  final ClassElement fromClass;
  final List<SpecifiedTable> tables;
  final List<DartType> daos;

  SpecifiedDatabase(this.fromClass, this.tables, this.daos);
}
