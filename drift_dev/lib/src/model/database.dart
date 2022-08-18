import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:drift_dev/moor_generator.dart';
import 'package:drift_dev/src/analyzer/runner/file_graph.dart';

/// Abstract class for database and dao elements.
abstract class BaseDriftAccessor implements HasDeclaration {
  @override
  final DatabaseOrDaoDeclaration? declaration;

  /// The [ClassElement] that was annotated with `UseMoor` or `UseDao`.
  ClassElement? get fromClass => declaration?.fromClass;

  /// All tables that have been declared on this accessor directly.
  ///
  /// This contains the `tables` field from a `UseMoor` or `UseDao` annotation,
  /// but not tables that are declared in imported moor files. Use [tables] for
  /// that.
  final List<DriftTable> declaredTables;

  /// All views that have been declared on this accessor directly.
  ///
  /// This contains the `views` field from a `DriftDatabase` or `UseDao`
  /// annotation, but not tables that are declared in imported moor files.
  /// Use [views] for that.
  final List<MoorView> declaredViews;

  /// The `includes` field from the `UseMoor` or `UseDao` annotation.
  final List<String> declaredIncludes;

  /// All queries declared directly in the `UseMoor` or `UseDao` annotation.
  final List<DeclaredQuery> declaredQueries;

  /// All entities for this database accessor. This contains [declaredTables]
  /// and all tables, triggers and other entities available through includes.
  List<DriftSchemaEntity> entities = [];

  /// All tables for this database accessor. This contains the [declaredTables]
  /// and all tables that are reachable through includes.
  Iterable<DriftTable> get tables => entities.whereType();

  /// All views for this database accesssor.
  Iterable<MoorView> get views => entities.whereType();

  /// All resolved queries.
  ///
  /// This includes the resolve result for queries that were declared in the
  /// same annotation, and queries that were in declared files.
  List<SqlQuery>? queries = [];

  /// Resolved imports from this file.
  List<FoundFile>? imports = [];

  BaseDriftAccessor._(this.declaration, this.declaredTables, this.declaredViews,
      this.declaredIncludes, this.declaredQueries);
}

/// A database, declared via a `UseMoor` annotation on a Dart class.
class Database extends BaseDriftAccessor {
  final List<DartType> daos;

  /// If the source database class overrides `schemaVersion` and returns a
  /// simple integer literal, stores that version.
  ///
  /// This is optionally used by the migration tooling to store the schema in a
  /// versioned file.
  int? schemaVersion;

  Database({
    this.daos = const [],
    this.schemaVersion,
    DatabaseOrDaoDeclaration? declaration,
    List<DriftTable> declaredTables = const [],
    List<MoorView> declaredViews = const [],
    List<String> declaredIncludes = const [],
    List<DeclaredQuery> declaredQueries = const [],
  }) : super._(declaration, declaredTables, declaredViews, declaredIncludes,
            declaredQueries);
}

/// A dao, declared via an `UseDao` annotation on a Dart class.
class Dao extends BaseDriftAccessor {
  /// The database class this dao belongs to.
  final DartType dbClass;

  Dao({
    required this.dbClass,
    DatabaseOrDaoDeclaration? declaration,
    required List<DriftTable> declaredTables,
    List<MoorView> declaredViews = const [],
    required List<String> declaredIncludes,
    required List<DeclaredQuery> declaredQueries,
  }) : super._(declaration, declaredTables, declaredViews, declaredIncludes,
            declaredQueries);
}
