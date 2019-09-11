import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:moor_generator/src/analyzer/runner/file_graph.dart';
import 'package:moor_generator/src/model/specified_table.dart';
import 'package:moor_generator/src/model/sql_query.dart';

class SpecifiedDbAccessor {
  final ClassElement fromClass;

  final List<SpecifiedTable> tables;
  final List<String> includes;
  final List<DeclaredQuery> queries;

  List<FoundFile> resolvedImports = [];
  List<SqlQuery> resolvedQueries = const [];

  SpecifiedDbAccessor(this.fromClass, this.tables, this.includes, this.queries);
}

/// Model generated from a class that is annotated with `UseDao`.
class SpecifiedDao extends SpecifiedDbAccessor {
  /// The database class this dao belongs to.
  final DartType dbClass;

  SpecifiedDao(
      ClassElement fromClass,
      this.dbClass,
      List<SpecifiedTable> tables,
      List<String> includes,
      List<DeclaredQuery> queries)
      : super(fromClass, tables, includes, queries);
}

class SpecifiedDatabase extends SpecifiedDbAccessor {
  final List<DartType> daos;

  SpecifiedDatabase(ClassElement fromClass, List<SpecifiedTable> tables,
      this.daos, List<String> includes, List<DeclaredQuery> queries)
      : super(fromClass, tables, includes, queries);
}
