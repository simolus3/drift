import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:moor_generator/src/model/specified_table.dart';
import 'package:moor_generator/src/model/sql_query.dart';

class SpecifiedDatabase {
  final ClassElement fromClass;
  final List<SpecifiedTable> tables;
  final List<DartType> daos;
  final List<SqlQuery> queries;

  SpecifiedDatabase(this.fromClass, this.tables, this.daos, this.queries);
}
