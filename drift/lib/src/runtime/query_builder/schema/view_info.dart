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
abstract class ViewInfo<Self extends View, Row>
    implements ResultSetImplementation<Self, Row> {
  @override
  String get entityName;

  /// The `CREATE VIEW` sql statement that can be used to create this view.
  String? get createViewStmt;

  /// Predefined query from `View.as()`
  Query? get query;
}
