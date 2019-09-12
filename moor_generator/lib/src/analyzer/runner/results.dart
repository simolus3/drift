import 'package:meta/meta.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:moor_generator/src/analyzer/runner/file_graph.dart';
import 'package:moor_generator/src/model/specified_db_classes.dart';
import 'package:moor_generator/src/model/specified_table.dart';
import 'package:moor_generator/src/model/sql_query.dart';
import 'package:sqlparser/sqlparser.dart';

abstract class FileResult {
  final List<SpecifiedTable> declaredTables;

  FileResult(this.declaredTables);
}

class ParsedDartFile extends FileResult {
  final LibraryElement library;

  final List<SpecifiedDao> declaredDaos;
  final List<SpecifiedDatabase> declaredDatabases;

  Iterable<SpecifiedDbAccessor> get dbAccessors =>
      declaredDatabases.cast<SpecifiedDbAccessor>().followedBy(declaredDaos);

  ParsedDartFile(
      {@required this.library,
      List<SpecifiedTable> declaredTables = const [],
      this.declaredDaos = const [],
      this.declaredDatabases = const []})
      : super(declaredTables);
}

class ParsedMoorFile extends FileResult {
  final ParseResult parseResult;
  MoorFile get parsedFile => parseResult.rootNode as MoorFile;

  final List<ImportStatement> imports;
  final List<DeclaredQuery> queries;

  List<SqlQuery> resolvedQueries;
  Map<ImportStatement, FoundFile> resolvedImports;

  ParsedMoorFile(this.parseResult,
      {List<SpecifiedTable> declaredTables = const [],
      this.queries = const [],
      this.imports = const []})
      : super(declaredTables);
}
