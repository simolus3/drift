// ignore_for_file: unused_field

part of 'manager.dart';

/// A class for creating filters based on references to other tables.
class ReferenceColumnFilters<FC extends FilterComposer> {
  final FC _composer;

  /// This class is used to create filters based on references to other tables.
  /// ```dart
  /// managers.category.filter((f) => f.todos.exist((f) => f.done(true));
  /// ```
  /// In the above example, `f.todos` is a [ReferenceColumnFilters] class
  /// that is used to create filters based on the reference to the `todos` table.
  ///
  const ReferenceColumnFilters(this._composer);

  /// If any of these references exist, this filter will be true.
  /// You may pass in a [filter] to filter the referenced columns.
  /// ```dart
  /// managers.category.filter((f) => f.todos.exist((f) => f.done(true));
  /// ```
  /// This will return all categories that have at least one todo that is done.
  ComposableFilter exist([ComposableFilter Function(FC f)? filter]) {
    return filter?.call(_composer) ?? _composer.all();
  }

  /// Filter on the count of references.
  /// You may pass in a [filter] to filter the referenced columns.
  /// ```dart
  /// managers.category.filter((f) => f.todos.count((f) => f.done(true)).equals(0)));
  /// ```
  /// This will return all categories that have no todos that are done.
  ///
  /// If this table has more that 1 primary key and doesn't have a rowid,
  /// this column filter will throw an error.
  ColumnFilters<int> count([ComposableFilter Function(FC f)? filter]) {
    // The source table that this ColumnFilters is referencing
    final table = (_composer.$joinBuilder!.currentTable as TableInfo);

    // When counting use an aggregate we have to supply a single column
    // to count
    final Expression expressionForGrouping;
    // If the table uses a rowid, we can use that
    if (!table.withoutRowId) {
      expressionForGrouping = table.rowId;
    } else {
      final primaryKeys = table.primaryKey;
      // If the table has only one primary key, we can use that
      if (primaryKeys.length == 1) {
        expressionForGrouping = primaryKeys.first;
      } else {
        // If the table has multiple primary keys, we need to concatenate them
        // todo: we can concatenate them using the `||` operator to make it a single column
        throw UnimplementedError(
            'Cannot count on a table with multiple primary keys and no rowid');
      }
    }

    // Create the expression for the having clause of the count filter
    final havingFilter = filter?.call(_composer) ?? _composer.all();

    // Create the group by builders for the count filter
    // The having clause will be set later by [_BaseColumnFilters.$composableFilter]
    // It is possible that the filter that the user provided has a group by clause
    // nested inside it, so we need to add it to the group by builders
    final groupByBuilders = [
      ...havingFilter.groupByBuilders,
      GroupByBuilder([expressionForGrouping], having: null)
    ];

    // Create the join builders for the count filter
    // We are passing the join builder of the current filter to the count filter
    // as well as any join builders that may have been created by the filter
    // the user provided
    final joinBuilder = {...havingFilter.joinBuilders, _composer.$joinBuilder!};

    // Return the count filter
    return ColumnFilters(countAll(filter: havingFilter.expression),
        joinBuilders: joinBuilder, groupByBuilders: groupByBuilders);
  }
}
