import 'package:json_annotation/json_annotation.dart';

import 'dart.dart';
import 'element.dart';
import 'table.dart';
import 'query.dart';
import 'view.dart';

part '../../generated/analysis/results/database.g.dart';

/// Abstract base class for databases and DAO declarations.
abstract class BaseDriftAccessor extends DriftElement {
  /// All tables that have been declared on this accessor directly.
  ///
  /// This contains the `tables` field from a `DriftDatabase` or `DriftAccessor`
  /// annotation, but not tables that are declared in imported files.
  final List<DriftTable> declaredTables;

  /// All views that have been declared on this accessor directly.
  ///
  /// This contains the `views` field from a `DriftDatabase` or `DriftAccessor`
  /// annotation, but not views that are declared in imported files.
  final List<DriftView> declaredViews;

  /// The `includes` field from the annotation.
  final List<Uri> declaredIncludes;

  /// All queries declared directly in the annotation.
  final List<QueryOnAccessor> declaredQueries;

  BaseDriftAccessor({
    required DriftElementId id,
    required DriftDeclaration declaration,
    required this.declaredTables,
    required this.declaredViews,
    required this.declaredIncludes,
    required this.declaredQueries,
  }) : super(id, declaration);

  @override
  Iterable<DriftElement> get references => [
        // todo: Track dependencies on includes somehow
        ...declaredTables,
        ...declaredViews,
      ];
}

/// A database, declared via a `DriftDatabase` annotation on a Dart class.
class DriftDatabase extends BaseDriftAccessor {
  /// If the source database class overrides `schemaVersion` and returns a
  /// simple integer literal, stores that version.
  ///
  /// This is optionally used by the migration tooling to store the schema in a
  /// versioned file.
  final int? schemaVersion;

  final List<DatabaseAccessor> accessors;

  DriftDatabase({
    required super.id,
    required super.declaration,
    required super.declaredTables,
    required super.declaredViews,
    required super.declaredIncludes,
    required super.declaredQueries,
    this.schemaVersion,
    this.accessors = const [],
  });
}

/// A Dart class with a similar API to a database, providing a view over a
/// subset of tables.
class DatabaseAccessor extends BaseDriftAccessor {
  /// The database class this dao belongs to.
  final AnnotatedDartCode databaseClass;

  final AnnotatedDartCode ownType;

  DatabaseAccessor({
    required super.id,
    required super.declaration,
    required super.declaredTables,
    required super.declaredViews,
    required super.declaredIncludes,
    required super.declaredQueries,
    required this.databaseClass,
    required this.ownType,
  });
}

/// A query defined on a [BaseDriftAccessor].
///
/// Similar to a [DefinedSqlQuery] defined in a `.drift` file, most of the SQL
/// analysis happens during code generation because intermediate state is hard
/// to serialize and there are little benefits of analyzing queries early.
@JsonSerializable()
class QueryOnAccessor implements DriftQueryDeclaration {
  @override
  final String name;
  final String sql;

  QueryOnAccessor(this.name, this.sql);

  factory QueryOnAccessor.fromJson(Map json) => _$QueryOnAccessorFromJson(json);

  Map<String, Object?> toJson() => _$QueryOnAccessorToJson(this);
}
