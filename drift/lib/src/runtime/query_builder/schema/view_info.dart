part of '../query_builder.dart';

/// A sqlite view.
///
/// In drift, views can only be declared in `.drift` files.
///
/// For more information on views, see the [CREATE VIEW][sqlite-docs]
/// documentation from sqlite, or the [entry on sqlitetutorial.net][sql-tut].
///
/// [sqlite-docs]: https://www.sqlite.org/lang_createview.html
/// [sql-tut]: https://www.sqlitetutorial.net/sqlite-create-view/
abstract class ViewInfo<Self extends HasResultSet, Row>
    implements ResultSetImplementation<Self, Row> {
  @override
  String get entityName;

  /// The `CREATE VIEW` sql statement that can be used to create this view.
  ///
  /// This will be null if the view was defined in Dart.
  @Deprecated('Use createViewStatements instead')
  String? get createViewStmt => createViewStatements?.values.first;

  /// The `CREATE VIEW` sql statement that can be used to create this view,
  /// depending on the dialect used by the current database.
  ///
  /// This will be null if the view was defined in Dart.
  Map<SqlDialect, String>? get createViewStatements;

  /// Predefined query from `View.as()`
  ///
  /// This will be null if the view was defined in a `.drift` file.
  Query? get query;

  /// All tables that this view reads from.
  ///
  /// If this view reads from other views, the [readTables] of that view are
  /// also included in this [readTables] set.
  Set<String> get readTables;

  Map<String, GeneratedColumn>? _columnsByName;

  @override
  Map<String, GeneratedColumn> get columnsByName {
    return _columnsByName ??= {
      for (final column in $columns) column.$name: column
    };
  }
}
