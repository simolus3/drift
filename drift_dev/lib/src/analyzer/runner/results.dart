import 'package:analyzer/dart/element/element.dart';
import 'package:drift_dev/moor_generator.dart';
import 'package:drift_dev/src/analyzer/runner/file_graph.dart';
import 'package:sqlparser/sqlparser.dart';

abstract class FileResult {
  final List<DriftSchemaEntity> declaredEntities;

  Iterable<DriftTable> get declaredTables =>
      declaredEntities.whereType<DriftTable>();
  Iterable<MoorView> get declaredViews =>
      declaredEntities.whereType<MoorView>();

  FileResult(this.declaredEntities);
}

class ParsedDartFile extends FileResult {
  final LibraryElement library;

  final List<Dao> declaredDaos;
  final List<Database> declaredDatabases;

  Iterable<BaseDriftAccessor> get dbAccessors =>
      declaredDatabases.cast<BaseDriftAccessor>().followedBy(declaredDaos);

  ParsedDartFile(
      {required this.library,
      List<DriftTable> declaredTables = const [],
      this.declaredDaos = const [],
      this.declaredDatabases = const []})
      : super(declaredTables);
}

class ParsedDriftFile extends FileResult {
  final ParseResult parseResult;
  DriftFile get parsedFile => parseResult.rootNode as DriftFile;

  final List<ImportStatement> imports;
  final List<DeclaredQuery> queries;

  /// Schema component that are neither tables nor queries. This can include
  /// triggers or indexes.
  final List<PartOfDriftFile> otherComponents;

  List<SqlQuery>? resolvedQueries;
  Map<ImportStatement, FoundFile>? resolvedImports;

  ParsedDriftFile(
    this.parseResult, {
    List<DriftSchemaEntity> declaredEntities = const [],
    this.queries = const [],
    this.imports = const [],
    this.otherComponents = const [],
  }) : super(declaredEntities);
}
