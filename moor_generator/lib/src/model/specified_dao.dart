import 'package:analyzer/dart/element/element.dart';
import 'package:moor_generator/src/model/specified_table.dart';
import 'package:moor_generator/src/model/sql_query.dart';

/// Model generated from a class that is annotated with `UseDao`.
class SpecifiedDao {
  final ClassElement fromClass;
  final List<SpecifiedTable> tables;
  final List<SqlQuery> queries;

  SpecifiedDao(this.fromClass, this.tables, this.queries);
}
